pragma solidity ^0.4.18;

import '../token/BalanceHistoryToken.sol';
import '../token/DelegatedTransferToken.sol';


contract RewardsToken is BalanceHistoryToken, DelegatedTransferToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  /**
   * @notice Construct RewardsToken and assign initial balances.
   */
  function RewardsToken(string _name,
    string _symbol, 
    uint8 _decimals, 
    uint256 _totalSupply,
    address[] _initialHolders, 
    uint256[] _initialAmounts) 
  public {

    name = _name;
    decimals = _decimals;
    symbol = _symbol;
    totalSupply = _totalSupply;

    uint256 amountAssigned = 0;
    require(_initialHolders.length == _initialAmounts.length);
    for(uint256 i = 0; i < _initialAmounts.length; i++) {
      setBalanceOf(_initialHolders[i], _initialAmounts[i]);
      amountAssigned = amountAssigned + _initialAmounts[i];
    }

    require(_totalSupply == amountAssigned);
  }

}