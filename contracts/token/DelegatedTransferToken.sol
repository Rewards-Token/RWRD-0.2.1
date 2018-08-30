
pragma solidity ^0.4.18;

import '../token/TokenTransferDelegate.sol';
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract DelegatedTransferToken is StandardToken, Ownable {

  address public delegate;
  bool public delegateSet;

  event DelegateAdded(address delegate);
  event DelegateRemoved();

  modifier delegateAllowsTransfer(address _from, address _to) {
    require(address(delegate) == 0 || TokenTransferDelegate(delegate).isTransferAllowed(_from, _to));
    _;
  }

  modifier onlyDelegate() {
    require(msg.sender == address(delegate));
    _;
  }

  function DelegatedTransferToken()
  public {
    delegate = address(0);
    delegateSet = false;
  }

  function addDelegate(address _delegate)
  public
  onlyOwner {
    require( ( ! delegateSet) && TokenTransferDelegate(_delegate).isTokenTransferDelegate());
    delegate = _delegate;
    delegateSet = true;
    DelegateAdded(_delegate);
  }

  function removeDelegate()
  public
  onlyDelegate {
    delegate = address(0);
    DelegateRemoved();
  }

  function transfer(address _to, uint256 _value) 
  public 
  delegateAllowsTransfer(msg.sender, _to) 
  returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) 
  public 
  delegateAllowsTransfer(_from, _to) 
  returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) 
  public 
  delegateAllowsTransfer(msg.sender, _spender) 
  returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) 
  public 
  delegateAllowsTransfer(msg.sender, _spender) 
  returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) 
  public
  delegateAllowsTransfer(msg.sender, _spender)
  returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}
