

pragma solidity ^0.4.18;

import '../token/BalanceHistoryToken.sol';

contract SimpleBalanceHistoryToken is BalanceHistoryToken {
  
  string public name = "Simple BalanceHistoryToken for testing only";
  uint8 public decimals = 0;
  string public symbol = "BHT";
  uint256 public totalSupply = 100;

  function SimpleBalanceHistoryToken() {
    setBalanceOf(msg.sender, totalSupply);
  }

}