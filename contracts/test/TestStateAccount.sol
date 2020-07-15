pragma solidity ^0.5.15;

import {StateAccount} from "../libs/StateAccount.sol";

contract TestStateAccount {
  using StateAccount for uint256;

  function accountID(uint256 account) external pure returns (uint256) {
    return account.accountID();
  }

  function tokenType(uint256 account) external pure returns (uint256) {
    return account.tokenType();
  }

  function balance(uint256 account) external pure returns (uint256) {
    return account.balance();
  }

  function nonce(uint256 account) external pure returns (uint256) {
    return account.nonce();
  }

  function incrementNonce(uint256 account) external pure returns (uint256, bool) {
    return account.incrementNonce();
  }

  function balanceSafeAdd(uint256 account, uint256 amount) external pure returns (uint256, bool) {
    return account.balanceSafeAdd(amount);
  }

  function balanceSafeSub(uint256 account, uint256 amount) external pure returns (uint256, bool) {
    return account.balanceSafeSub(amount);
  }

  function hash(uint256 account) external pure returns (bytes32 res) {
    return account.hash();
  }
}
