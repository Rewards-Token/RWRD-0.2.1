
pragma solidity ^0.4.16;

import '../token/BalanceHistoryToken.sol';
import '../storage/CommunityVotingPool.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * 
 * @title Vote-tallying contract for Rewards platform.
 * @author Rewards Blockchain
 * @dev Original source: https://github.com/ethereum/ethereum-org/blob/3a58cf7b19e738820f928a2989a99799e18518b4/solidity/dao-association.sol
 *      (or ethereum.org/dao)
 */
contract Association is Ownable {

  event ProposalAdded(uint proposalNumber, address recipient, uint amount, string description, bytes transactionBytecode);
  event ProposalFinalized(uint proposalNumber, uint votesFor, uint votesAgainst, bool passed);
  event ProposalExecuted(uint proposalNumber, bytes transactionBytecode, uint transactionId);

  event TokenHolderVoted(uint proposalNumber, bool position, address voter);
  event RewardsUserVoted(uint proposalNumber, bool position, string  voter);

  event CommunityVotingPoolSet(address walletAddress);

  enum Vote { NONE, VOTED_FOR, VOTED_AGAINST }
  enum ProposalState { ERROR, VOTING, FINALIZED_PASSED, FINALIZED_FAILED, EXECUTED }

  struct Proposal {
    address recipient;
    uint amount;
    string description;
    uint votingDeadline;
    bytes32 proposalHash;

    address[] votingAddresses;
    uint8[] onchainVotes;
    mapping (address => Vote) voteByAddress;

    bytes32[] votingUsernameHashes;
    uint8[] offchainVotes;
    mapping (bytes32 => Vote) voteByUsernameHash;

    ProposalState state;
    uint transactionId; // if the proposal passes, this is the ID of the transaction in the CommunityVotingPool

    uint createdBlockNum; // number of block when proposal was created; used to determine who can vote

    uint votesFor;
    uint votesAgainst;
  }

  uint public minimumQuorum = 0;
  Proposal[] public proposals;
  uint public numProposals;
  BalanceHistoryToken public token;

  CommunityVotingPool public communityVotingPool;

  // State variables
  bool public communityVotingPoolSet;


  /**
   * Only allow callers allowed to vote on proposal #proposalNumber.
   */
  modifier onlyEnfranchised(uint proposalNumber) {
    require(token.balanceOfAt(msg.sender, proposals[proposalNumber].createdBlockNum) > 0);
    _;
  }

  /**
   * Proposal must be in a certain state.
   */
   modifier onlyInState(uint proposalNumber, ProposalState state) {
    require(proposals[proposalNumber].state == state);
    _;
   }

  /**
   * Constructor function
   *
   * First time setup
   */
  function Association(BalanceHistoryToken tokenAddress)
  public {
    token = BalanceHistoryToken(tokenAddress);
    communityVotingPoolSet = false;
  }

  
  function getProposalOnchainVotes(uint proposalNumber)
  public
  view
  returns(uint8[]) {
    return proposals[proposalNumber].onchainVotes;
  }

  function getProposalOffchainVotes(uint proposalNumber)
  public
  view
  returns(uint8[]) {
    return proposals[proposalNumber].offchainVotes;
  }

  function getProposalVotingAddresses(uint proposalNumber)
  public
  view
  returns(address[]) {
    return proposals[proposalNumber].votingAddresses;
  }

  function getProposalVotingUsernameHashes(uint proposalNumber)
  public
  view
  returns(bytes32[]) {
    return proposals[proposalNumber].votingUsernameHashes;
  }

  function getProposalState(uint proposalNumber)
  public
  view
  returns(uint) {
    return uint(proposals[proposalNumber].state);
  }

  function getProposalTransactionId(uint proposalNumber)
  public
  view
  returns(uint) {
    Proposal storage p = proposals[proposalNumber];
    require(p.state == ProposalState.EXECUTED);
    return p.transactionId;
  }

  /**
   * Add Proposal
   *
   * Propose to send `baseRwrdAmount / BalanceHistoryToken.decimals` RWRD to `beneficiary` for `jobDescription`. 
   * `transactionBytecode ? Contains : Does not contain` code.
   *
   * @param beneficiary who to send the ether to
   * @param baseRwrdAmount amount of RWRD to send in base units
   * @param jobDescription Description of job
   * @param transactionBytecode bytecode of transaction
   */
  function newProposal(address beneficiary, 
    uint256 baseRwrdAmount, 
    string jobDescription, 
    bytes transactionBytecode, 
    uint256 votingPeriodSeconds) 
  public
  onlyOwner 
  returns(uint proposalNumber) {
    proposalNumber = proposals.length++;
    Proposal storage p = proposals[proposalNumber];
    
    p.recipient = beneficiary;
    p.amount = baseRwrdAmount;
    p.description = jobDescription;
    p.proposalHash = keccak256(beneficiary, baseRwrdAmount, transactionBytecode);
    p.votingDeadline = now + votingPeriodSeconds;
    p.state = ProposalState.VOTING;
    p.votesFor = 0;
    p.votesAgainst = 0;
    p.createdBlockNum = block.number;

    ProposalAdded(proposalNumber, beneficiary, baseRwrdAmount, jobDescription, transactionBytecode);
    numProposals = proposalNumber + 1;

    return proposalNumber;
  }

  /**
   * Check whether an offchain user with a given username has voted.
   *
   * @param proposalNumber ID of proposal for which vote is queried
   * @param usernameHash keccak256(<the username in question>)
   */
  function hasVoted(uint proposalNumber, 
    bytes32 usernameHash) 
  public
  view
  returns(bool userVoted) {
    Proposal storage p = proposals[proposalNumber];
    return p.voteByUsernameHash[usernameHash] != Vote.NONE;
  }

  /**
   * Check if a proposal code matches
   *
   * @param proposalNumber ID number of the proposal to query
   * @param beneficiary who to send the ether to
   * @param baseRwrdAmount amount of ether to send
   * @param transactionBytecode bytecode of transaction
   */
  function checkProposalCode(uint proposalNumber, 
    address beneficiary, 
    uint baseRwrdAmount, 
    bytes transactionBytecode) 
  public
  view 
  returns(bool codeChecksOut) {
    Proposal storage p = proposals[proposalNumber];
    return p.proposalHash == keccak256(beneficiary, baseRwrdAmount, transactionBytecode);
  }

  /**
   * @notice Set the association's (Gnosis-compatible) multisig wallet, to which it will submit and confirm transactions.
   * @notice Before calling, ensure that:
   * @notice  - this contract is an owner of the multisig wallet.
   * @notice  - the multisig wallet is compatible with Gnosis'.
   * @notice Otherwise, this call will fail and the MSW will remain unset.
   *
   * @notice WARNING: once the multisig wallet address is successfully set,
   * @notice IT CANNOT BE RESET--THIS METHOD MAY BE CALLED SUCCESSFULLY ONLY ONCE.
   *
   * @param newWalletAddress address of multisig wallet
   */
  function setCommunityVotingPool(address newWalletAddress)
  public
  onlyOwner {
    require( ! communityVotingPoolSet);
    
    communityVotingPool = CommunityVotingPool(newWalletAddress);

    require(communityVotingPool.isOwner(address(this)));

    communityVotingPoolSet = true;

    CommunityVotingPoolSet(newWalletAddress);
  }

  /**
   * Log a vote for a proposal
   *
   * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
   *
   * @param proposalNumber number of proposal
   * @param supportsProposal either in favor or against it
   */
  function vote(uint proposalNumber, 
    bool supportsProposal)
  public
  onlyEnfranchised(proposalNumber)
  onlyInState(proposalNumber, ProposalState.VOTING) {
    Proposal storage p = proposals[proposalNumber];
    require(p.voteByAddress[msg.sender] == Vote.NONE);

    Vote userVote;
    if (supportsProposal) {
      userVote = Vote.VOTED_FOR;
      p.votesFor = p.votesFor + 1;
    } else {
      userVote = Vote.VOTED_AGAINST;
      p.votesAgainst = p.votesAgainst + 1;
    }
    p.voteByAddress[msg.sender] = userVote;

    p.votingAddresses.push(msg.sender);
    p.onchainVotes.push(uint8(userVote));

    TokenHolderVoted(proposalNumber, supportsProposal, msg.sender);
  }

  function voteOffchainUser(uint proposalNumber, 
    bool supportsProposal, 
    string username)
  public
  onlyOwner 
  onlyInState(proposalNumber, ProposalState.VOTING) {
    Proposal storage p = proposals[proposalNumber];
    bytes32 usernameHash = keccak256(username);
    require( ! hasVoted(proposalNumber, usernameHash));

    Vote userVote;
    if (supportsProposal) {
      userVote = Vote.VOTED_FOR;
      p.votesFor = p.votesFor + 1;
    } else {
      userVote = Vote.VOTED_AGAINST;
      p.votesAgainst = p.votesAgainst + 1;
    }
    p.voteByUsernameHash[usernameHash] = userVote;

    p.votingUsernameHashes.push(usernameHash);
    p.offchainVotes.push(uint8(userVote));

    RewardsUserVoted(proposalNumber, supportsProposal, username);
  }

  /**
   * Finish the voting period, if possible.
   * Must be called before a proposal is executed.
   */
   function finalizeProposal(uint proposalNumber)
   public
   onlyInState(proposalNumber, ProposalState.VOTING) {
    Proposal storage p = proposals[proposalNumber];
    uint quorum = p.votesFor + p.votesAgainst;

    require(now > p.votingDeadline          // If it's past the voting deadline
        && quorum >= minimumQuorum);    // and the minimum quorum has been reached,
                        // voting may end.

    if (p.votesFor > p.votesAgainst) {
      p.state = ProposalState.FINALIZED_PASSED;
    } else {
      p.state = ProposalState.FINALIZED_FAILED;
    }
    ProposalFinalized(proposalNumber, p.votesFor, p.votesAgainst, p.votesFor > p.votesAgainst);

   }

  /**
   * Finish vote
   *
   * Count the votes proposal #`proposalNumber` and execute it if approved
   *
   * @param proposalNumber proposal number
   * @param transactionBytecode optional: if the transaction contained a bytecode, you need to send it
   */
  function executeProposal(uint proposalNumber, 
    bytes transactionBytecode)
  public
  onlyInState(proposalNumber, ProposalState.FINALIZED_PASSED) {
    Proposal storage p = proposals[proposalNumber];

    require(checkProposalCode(proposalNumber, p.recipient, p.amount, transactionBytecode)); // and the supplied code matches the proposal...

    uint transactionId = communityVotingPool.submitTransaction(p.recipient, p.amount, transactionBytecode);

    p.state = ProposalState.EXECUTED;
    p.transactionId = transactionId;

    ProposalExecuted(proposalNumber, transactionBytecode, transactionId);
  }
}
