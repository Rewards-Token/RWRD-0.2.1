
pragma solidity ^0.4.18;

import '../storage/MultiSigWallet.sol';

contract ICOFundsVault is MultiSigWallet {
  
  function ICOFundsVault(address[] _owners, uint _required) MultiSigWallet(_owners, _required) {
    // ...
  }

}