pragma solidity ^0.5.15;

import { AccountTree } from "./AccountTree.sol";
import { BLS } from "./libs/BLS.sol";

contract BLSAccountRegistry is AccountTree {
  uint256 constant SIGN_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

  constructor() public AccountTree() {}

  function register(uint256[2] calldata pubkey) external returns (uint256) {
  // Note that we don't have to check if compresed public key is in valid form.
    bytes32 leaf = keccak256(abi.encodePacked(pubkey));
    uint256 accountID = _updateSingle(leaf);
    return accountID;
  }

  function registerBatch(uint256[2][BATCH_SIZE] calldata pubkeys) external returns (uint256) {
    bytes32[BATCH_SIZE] memory leafs;
    for (uint256 i = 0; i < BATCH_SIZE; i++) {
      bytes32 leaf = keccak256(abi.encodePacked(pubkeys[i]));
      leafs[i] = leaf;
    }
    uint256 lowerOffset = _updateBatch(leafs);
    return lowerOffset;
  }

  function uncompressedExists(
    uint256[4] calldata uncompressed,
    uint256 accountIndex,
    bytes32[WITNESS_LENGTH - 1] calldata witness
  ) external view returns (bool) // uint256[2] memory

  {
    bytes32 leaf;
    if (uncompressed[2] & 1 == 1) {
      // FIX: use commented when bump sol to v06
      // leaf = keccak256(abi.encodePacked(uncompressed[0] | BLS.SIGN_MASK, uncompressed[1]));
      leaf = keccak256(abi.encodePacked(uncompressed[0] | SIGN_MASK, uncompressed[1]));
    } else {
      leaf = keccak256(abi.encodePacked(uncompressed[0], uncompressed[1]));
    }
    return _checkInclusion(leaf, accountIndex, witness);
  }

  function uncompressedExists2(uint256[4] calldata uncompressed, bytes32[WITNESS_LENGTH] calldata witness)
    external
    view
    returns (bool)
  {
    bytes32 leaf;
    if (uncompressed[2] & 1 == 1) {
      // FIX: use commented when bump sol to v06
      // leaf = keccak256(abi.encodePacked(uncompressed[0] & BLS.SIGN_MASK, uncompressed[1]));
      leaf = keccak256(abi.encodePacked(uncompressed[0] & SIGN_MASK, uncompressed[1]));
    } else {
      leaf = keccak256(abi.encodePacked(uncompressed[0], uncompressed[1]));
    }
    return _checkInclusion(leaf, witness);
  }

  function compressedExists(
    uint256[2] calldata compresed,
    uint256 accountIndex,
    bytes32[WITNESS_LENGTH - 1] calldata witness
  ) external view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(compresed));
    return _checkInclusion(leaf, accountIndex, witness);
  }

  function compressedExists2(uint256[2] calldata compresed, bytes32[WITNESS_LENGTH] calldata witness)
    external
    view
    returns (bool)
  {
    bytes32 leaf = keccak256(abi.encodePacked(compresed));
    return _checkInclusion(leaf, witness);
  }
}
