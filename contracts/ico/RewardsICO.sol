pragma solidity ^0.4.18;

import '../ico/PhaseStrategy.sol';
import '../token/RewardsToken.sol';
import '../token/TokenTransferDelegate.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * @title Rewards ICO contract
 */

contract RewardsICO is TokenTransferDelegate, Ownable {

  event PurchaseMade(address _owner, uint256 _tokenAmount, uint256 _weiAmount);

  uint public startFundingTime;           // In UNIX Time Format
  uint public endFundingTime;             // In UNIX Time Format            
  uint public totalCollectedWei;          
  uint public totalTokensSold;
  RewardsToken public tokenContract;
  address public verifier;
  address public vaultAddress;            // The address to hold the funds donated
  PhaseStrategy public phaseStrategy; // Object responsible for setting token price 
  bool public transfersAllowed;

  modifier addressIsVerified(address _owner, uint8 v, bytes32 r, bytes32 s) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 hash = keccak256(prefix, keccak256(_owner));

    require(ecrecover(hash, v, r, s) == verifier);
    _;
  }

  function testRecovery(address _owner, uint8 v, bytes32 r, bytes32 s) 
  public
  view
  addressIsVerified(_owner, v, r, s)
  returns (bool) {
    return true;
  }

  /**
   * Check parameters and initialize ICO.
   *
   * @param _vaultAddress Address of "vault" that will store collected ether.
   * @param _tokenAddress The token contract's address.
   * @param _verifierAddress The account responsible for authorizing access to the ICO.
   * @param _phaseStrategy A contract implementing the PhaseStrategy interface 
   *                         (see PhaseStrategy.sol)
   */
  function RewardsICO(address _vaultAddress, address _tokenAddress, address _verifierAddress, address _phaseStrategy) 
  public {
    phaseStrategy = PhaseStrategy(_phaseStrategy);
    require(phaseStrategy.isPhaseStrategyReady());

    startFundingTime = phaseStrategy.getPricingStartsAt();
    endFundingTime = phaseStrategy.getPricingEndsAt();
    require((endFundingTime >= now) && (endFundingTime > startFundingTime));

    vaultAddress = _vaultAddress;
    require(_vaultAddress != address(0));

    verifier = _verifierAddress;
    require(_verifierAddress != address(0));
    
    tokenContract = RewardsToken(_tokenAddress);
  }

  function allowTokenTransfers(bool _transfersAllowed)
  public
  onlyOwner {
    transfersAllowed = _transfersAllowed;
  }

  function isTransferAllowed(address /*_from*/, address /*_to*/) 
  public 
  view
  returns (bool) {
    return (transfersAllowed && phaseStrategy.transfersEnabled());
  }

  function invest(address _owner, uint8 v, bytes32 r, bytes32 s)
  public
  payable
  addressIsVerified(_owner, v, r, s) {

    require ((now >= startFundingTime) &&
      (now <= endFundingTime) &&
      (tokenContract.delegate() != address(0)) && // ?
      (msg.value != 0)
    );


    uint tokenAmount = phaseStrategy.calculatePrice(
      msg.value,                 // value
      totalCollectedWei,         // weiRaised 
      totalTokensSold,           // tokensSold
      _owner,                    // msgSender
      tokenContract.decimals()); // token's decimals

    require(tokenContract.transferFrom(vaultAddress, _owner, tokenAmount));
    totalTokensSold += tokenAmount;

    require(vaultAddress.send(msg.value));
    totalCollectedWei += msg.value;

    PurchaseMade(_owner, tokenAmount, msg.value);
  }

  /// @notice `finalizeFunding()` ends the Campaign by calling setting the
  ///  controller to 0, thereby ending the issuance of new tokens and stopping the
  ///  Campaign from receiving more ether
  /// @dev `finalizeFunding()` can only be called after the end of the funding period.

  function finalizeFunding() 
  public {
    require(now >= endFundingTime);
    tokenContract.removeDelegate();
  }


  /// @notice `onlyOwner` changes the location that ether is sent
  /// @param _newVaultAddress The address that will receive the ether sent to this
  ///                         Campaign
  function setVault(address _newVaultAddress) 
  public 
  onlyOwner {
    vaultAddress = _newVaultAddress;
  }

}
