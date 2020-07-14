pragma solidity ^0.5.15;

contract TestTxSer {
  uint256 public constant txLen = 12;
  uint256 public constant maskSender = 0xffffffff;
  uint256 public constant positionSender = 4;
  uint256 public constant maskReceiver = 0xffffffff;
  uint256 public constant positionReceiver = 8;
  uint256 public constant maskAmount = 0xffffffff;
  uint256 public constant positionAmount = 12;

  // struct Tx {
  //   uint32 sender;
  //   uint32 receiver;
  //   uint32 amount;
  // }


  function getAmountOf(bytes calldata _txs, uint256 index) external pure returns (uint256) {
    bytes memory txs = _txs;
    uint256 txSize = txs.length / txLen;
    require(txSize * txLen == txs.length, "excess data");

    uint256 amount;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let p_tx := add(txs, mul(index, txLen))
      amount := and(mload(add(p_tx, positionAmount)), maskAmount)
    }
    return amount;
  }

  function getSenderOf(bytes calldata _txs, uint256 index) external pure returns (uint256) {
    bytes memory txs = _txs;
    uint256 txSize = txs.length / txLen;
    require(txSize * txLen == txs.length, "excess data");

    uint256 sender;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let p_tx := add(txs, mul(index, txLen))
      sender := and(mload(add(p_tx, positionSender)), maskSender)
    }
    return sender;
  }

  function getReceiverOf(bytes calldata _txs, uint256 index) external pure returns (uint256) {
    bytes memory txs = _txs;
    uint256 txSize = txs.length / txLen;
    require(txSize * txLen == txs.length, "excess data");

    uint256 receiver;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let p_tx := add(txs, mul(index, txLen))
      receiver := and(mload(add(p_tx, positionReceiver)), maskReceiver)
    }
    return receiver;
  }
}