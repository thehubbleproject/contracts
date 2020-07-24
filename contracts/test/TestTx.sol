pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import { Tx } from "../libs/Tx.sol";

contract TestTx {
    using Tx for bytes;

    function serialize(
        uint256[] memory senders,
        uint256[] memory receivers,
        uint256[] memory amounts,
        bytes[] memory signatures
    ) public pure returns (bytes memory) {
        return Tx.serialize(senders, receivers, amounts, signatures);
    }

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

    function signatureOf(bytes calldata txs, uint256 index)
        external
        pure
        returns (bytes memory)
    {
        return txs.signatureOf(index);
    }

    function hashOf(bytes calldata txs, uint256 index)
        external
        pure
        returns (bytes32)
    {
        return txs.hashOf(index);
    }
}
