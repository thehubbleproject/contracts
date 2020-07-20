pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import {Types} from "../libs/Types.sol";

interface IFraudProof {
  function processBatch(
    bytes32 stateRoot,
    bytes calldata txs,
    Types.InvalidTransitionProof calldata proof
  ) external view returns (bytes32, bool);
}
