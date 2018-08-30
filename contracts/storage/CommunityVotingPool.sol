pragma solidity ^0.4.18;

import '../storage/MultiSigWallet.sol';
import '../token/RewardsToken.sol';

/**
 * @title Community voting pool: a multisig wallet that sends RWRD, not ether, with confirmed transactions.
 */
contract CommunityVotingPool is MultiSigWallet {
  
  address public tokenContract;
  bool public tokenContractSet;
  address public deployer;

  event TokenContractSet(address newTokenContract);

  function CommunityVotingPool(address[] _owners, uint _required) MultiSigWallet(_owners, _required) {
    //...
  }

  /**
   * @notice Reject sent ether.
   * @dev The CommunityVotingPool cannot receive ether--it holds only RWRD.
   */
  function() payable {
    revert();
  }

  /**
   * @notice Set the CommunityVotingPool's token contract.
   * @dev This is called at deployment time by whoever deployed the
   *      contract. It may only be called once.
   *      Setting the token contract outside of the constructor allows us to deploy
   *      the token contract before the community voting pool, which in turn allows us to specify
   *      the community voting pool as one of the initial holders of the token.
   */
  function setTokenContract(address _tokenContract)
  public
  onlyWallet {
    require( ! tokenContractSet);
    tokenContract = RewardsToken(_tokenContract);
    tokenContractSet = true;
    TokenContractSet(_tokenContract);
  }

  /**
   * @notice Allows anyone to execute a confirmed transaction.
   * @dev The transfer of RWRD tokens happens in two steps:
   *        1. The CommunityVotingPool approves withdrawal of tokens by the contract.
   *           Execution is considered complete when this is successful.
   *        2. The CommunityVotingPool calls a function on the contract.
   * 
   *      Warning: whether or not the function call in tx.data is succcessful, the transaction
   *      will be considered "executed" and cannot be called again.
   *
   * @param transactionId Transaction ID.
   */
  function executeTransaction(uint transactionId)
  public
  ownerExists(msg.sender)
  confirmed(transactionId, msg.sender)
  notExecuted(transactionId) {
    if (isConfirmed(transactionId)) {
      Transaction tx = transactions[transactionId];
      if (tx.value > 0) {
        require(RewardsToken(tokenContract).approve(tx.destination, tx.value));
        tx.executed = true;
      }
      if (tx.destination.call(tx.data)) {
        tx.executed = true;
        Execution(transactionId);
      }
      else {
        ExecutionFailure(transactionId);
      }
    }
  }

}