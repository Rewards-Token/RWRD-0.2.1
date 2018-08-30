pragma solidity ^0.4.18;



/**
 * @title Rewards private sale participant ledger
 */
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract PrivateSale is Ownable {

  mapping (address => uint256) public tokensForParticipant;
  mapping (address => bool) public participantRegistered;
  address[] public participants;

  uint256 public totalTokensSold;
  uint256 public tokenCap;

  function PrivateSale(uint256 _tokenCap) {
    tokenCap = _tokenCap;
  }

  function assignTokens(address participant, uint256 tokens) 
  public
  onlyOwner {
    require(totalTokensSold + tokens <= tokenCap);
    if ( ! participantRegistered[participant]) {
      participants.push(participant);
      participantRegistered[participant] = true;
    }
    tokensForParticipant[participant] += tokens;
    totalTokensSold += tokens;
  }
}