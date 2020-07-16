pragma solidity ^0.5.15;

import {Tx} from "../libs/Tx.sol";

contract TestTx {
    using Tx for bytes;

    function hasExcessData(bytes calldata txs) external pure returns (bool) {
        return txs.hasExcessData();
    }

    function size(bytes calldata txs) external pure returns (uint256) {
        return txs.size();
    }

    function amountOf(bytes calldata txs, uint256 index)
        external
        pure
        returns (uint256)
    {
        return txs.amountOf(index);
    }

    function senderOf(bytes calldata txs, uint256 index)
        external
        pure
        returns (uint256)
    {
        return txs.senderOf(index);
    }

    function receiverOf(bytes calldata txs, uint256 index)
        external
        pure
        returns (uint256)
    {
        return txs.receiverOf(index);
    }

    function hashOf(bytes calldata txs, uint256 index)
        external
        pure
        returns (bytes32)
    {
        return txs.hashOf(index);
    }
}
