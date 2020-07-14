const TestTxSer = artifacts.require('TestTxSer');
import { TestTxSerInstance } from '../types/truffle-contracts';

interface Tx {
  sender: number;
  receiver: number;
  amount: number;
}

let amountLen = 4;
let senderLen = 4;
let receiverLen = 4;

function serialize(txs: Tx[]): string {
  let serialized = '0x';
  for (let i = 0; i < txs.length; i++) {
    let tx = txs[i];
    let sender = web3.utils.padLeft(web3.utils.toHex(tx.sender), senderLen * 2);
    let receiver = web3.utils.padLeft(web3.utils.toHex(tx.receiver), receiverLen * 2);
    let amount = web3.utils.padLeft(web3.utils.toHex(tx.amount), amountLen * 2);
    serialized = serialized + sender.slice(2) + receiver.slice(2) + amount.slice(2);
  }
  return serialized;
}

contract('Tx Serialization', (accounts) => {
  let ser: TestTxSerInstance;
  beforeEach(async function () {
    ser = await TestTxSer.new();
  });
  it('parse transaction', async function () {
    const txSize = 128;
    const txs: Tx[] = [];
    for (let i = 0; i < txSize; i++) {
      const sender = web3.utils.hexToNumber(web3.utils.randomHex(senderLen));
      const receiver = web3.utils.hexToNumber(web3.utils.randomHex(receiverLen));
      const amount = web3.utils.hexToNumber(web3.utils.randomHex(amountLen));
      txs.push({ sender, receiver, amount });
    }
    const serialized = serialize(txs);
    for (let i = 0; i < txSize; i++) {
      let amount = (await ser.getAmountOf(serialized, i)).toNumber();
      assert.equal(amount, txs[i].amount);
      let sender = (await ser.getSenderOf(serialized, i)).toNumber();
      assert.equal(sender, txs[i].sender);
      let receiver = (await ser.getReceiverOf(serialized, i)).toNumber();
      assert.equal(receiver, txs[i].receiver);
    }
  });
});
