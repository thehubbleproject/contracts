pragma solidity ^0.5.15;

library Tx {
    // // transaction:
    // // [sender<4>|receiver<4>|amount<4>]
    // uint256 public constant TX_LEN = 12;
    // uint256 public constant MASK_TX = 0xffffffffffffffffffffffff;
    // uint256 public constant MASK_STATE_INDEX = 0xffffffff;
    // uint256 public constant MASK_AMOUNT = 0xffffffff;
    // // positions in bytes
    // uint256 public constant POSITION_SENDER = 4;
    // uint256 public constant POSITION_RECEIVER = 8;
    // uint256 public constant POSITION_AMOUNT = 12;

    // transaction:
    // [sender<4>|receiver<4>|amount<4>|signature<64>]
    uint256 public constant RAW_TX_LEN = 12;
    uint256 public constant TX_LEN = 76;
    uint256 public constant MASK_TX = 0xffffffffffffffffffffffff;
    uint256 public constant MASK_STATE_INDEX = 0xffffffff;
    uint256 public constant MASK_AMOUNT = 0xffffffff;
    // positions in bytes
    uint256 public constant POSITION_SENDER = 4;
    uint256 public constant POSITION_RECEIVER = 8;
    uint256 public constant POSITION_AMOUNT = 12;
    uint256 public constant POSITION_SIGNATURE_X = 44;
    uint256 public constant POSITION_SIGNATURE_Y = 76;

    function serialize(
        uint256[] memory senders,
        uint256[] memory receivers,
        uint256[] memory amounts,
        bytes[] memory signatures
    ) internal pure returns (bytes memory) {
        uint256 batchSize = signatures.length;
        require(senders.length == batchSize, "bad sender size");
        require(receivers.length == batchSize, "bad receiver size");
        require(amounts.length == batchSize, "bad amount size");
        uint256 bound = 0x10000000000000000;
        // uint256 TX_LEN = 4 + 4 + 4 + 64;
        bytes memory serialized = new bytes(TX_LEN * batchSize);
        for (uint256 i = 0; i < batchSize; i++) {
            bytes memory signature = signatures[i];
            uint256 sender = senders[i];
            uint256 receiver = receivers[i];
            uint256 amount = amounts[i];
            require(signature.length == 64, "invalid signature");
            require(sender < bound, "invalid sender index");
            require(receiver < bound, "invalid receiver index");
            require(amount < bound, "invalid amount");
            bytes memory _tx = abi.encodePacked(
                uint32(sender),
                uint32(receiver),
                uint32(amount),
                signature
            );
            uint256 off = i * TX_LEN;
            for (uint256 j = 0; j < TX_LEN; j++) {
                serialized[j + off] = _tx[j];
            }
        }
        return serialized;
    }

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

    function signatureOf(bytes memory txs, uint256 index)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory signature = new bytes(64);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p_tx := add(txs, mul(index, TX_LEN))
            let x := mload(add(p_tx, POSITION_SIGNATURE_X))
            let y := mload(add(p_tx, POSITION_SIGNATURE_Y))
            mstore(add(signature, 64), x)
            mstore(add(signature, 96), y)
        }
        return signature;
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
            result := keccak256(p_tx, RAW_TX_LEN)
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
