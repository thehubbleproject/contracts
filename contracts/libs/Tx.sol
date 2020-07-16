pragma solidity ^0.5.15;

library Tx {
    // transaction:
    // [sender<4>|receiver<4>|amount<4>]
    uint256 public constant TX_LEN = 12;
    uint256 public constant MASK_TX = 0xffffffffffffffffffffffff;
    uint256 public constant MASK_STATE_INDEX = 0xffffffff;
    uint256 public constant MASK_AMOUNT = 0xffffffff;
    // positions in bytes
    uint256 public constant POSITION_SENDER = 4;
    uint256 public constant POSITION_RECEIVER = 8;
    uint256 public constant POSITION_AMOUNT = 12;

    function hasExcessData(bytes memory txs) internal pure returns (bool) {
        uint256 txSize = txs.length / TX_LEN;
        return txSize * TX_LEN != txs.length;
    }

    function size(bytes memory txs) internal pure returns (uint256) {
        uint256 txSize = txs.length / TX_LEN;
        return txSize;
    }

    function amountOf(bytes memory txs, uint256 index)
        internal
        pure
        returns (uint256 amount)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p_tx := add(txs, mul(index, TX_LEN))
            amount := and(mload(add(p_tx, POSITION_AMOUNT)), MASK_AMOUNT)
        }
        return amount;
    }

    function senderOf(bytes memory txs, uint256 index)
        internal
        pure
        returns (uint256 sender)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p_tx := add(txs, mul(index, TX_LEN))
            sender := and(mload(add(p_tx, POSITION_SENDER)), MASK_STATE_INDEX)
        }
    }

    function receiverOf(bytes memory txs, uint256 index)
        internal
        pure
        returns (uint256 receiver)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p_tx := add(txs, mul(index, TX_LEN))
            receiver := and(
                mload(add(p_tx, POSITION_RECEIVER)),
                MASK_STATE_INDEX
            )
        }
    }

    function hashOf(bytes memory txs, uint256 index)
        internal
        pure
        returns (bytes32 result)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p_tx := add(txs, add(mul(index, TX_LEN), 32))
            result := keccak256(p_tx, TX_LEN)
        }
    }

    function toLeafs(bytes memory txs)
        internal
        pure
        returns (bytes32[] memory)
    {
        uint256 batchSize = size(txs);
        bytes32[] memory buf = new bytes32[](batchSize);
        for (uint256 i = 0; i < batchSize; i++) {
            buf[i] = hashOf(txs, i);
        }
        return buf;
    }
}
