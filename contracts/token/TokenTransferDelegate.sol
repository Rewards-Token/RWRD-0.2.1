pragma solidity ^0.4.18;

contract TokenTransferDelegate {

  function isTokenTransferDelegate() public pure returns (bool) { return true; }
  function isTransferAllowed(address _from, address _to) public view returns (bool);
}
