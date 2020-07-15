pragma solidity ^0.5.15;

import {Tx} from "../libs/Tx.sol";

contract TestTx {
  function hasExcessData(bytes calldata txs) external pure returns (bool) {
    return Tx.hasExcessData(txs);
  }

  function size(bytes calldata txs) external pure returns (uint256) {
    return Tx.size(txs);
  }

  function amountOf(bytes calldata txs, uint256 index) external pure returns (uint256 amount) {
    return Tx.amountOf(txs, index);
  }

  function senderOf(bytes calldata txs, uint256 index) external pure returns (uint256 sender) {
    return Tx.senderOf(txs, index);
  }

  function receiverOf(bytes calldata txs, uint256 index) external pure returns (uint256 receiver) {
    return Tx.receiverOf(txs, index);
  }

  function hashOf(bytes calldata txs, uint256 index) external pure returns (bytes32 result) {
    return Tx.hashOf(txs, index);
  }

  function mapToPoint(bytes calldata txs, uint256 index) external view returns (uint256[2] memory) {
    return Tx.mapToPoint(txs, index);
  }
}
