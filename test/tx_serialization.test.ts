const TestTx = artifacts.require('TestTx');
import { TestTxInstance } from '../types/truffle-contracts';
import * as mcl from './mcl';
import { bnToHex } from './mcl';

interface Tx {
  sender: number;
  receiver: number;
  amount: number;
}

let amountLen = 4;
let senderLen = 4;
let receiverLen = 4;

function serialize(txs: Tx[]) {
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

function hash(tx: Tx) {
  return web3.utils.soliditySha3({ v: tx.sender, t: 'uint32' }, { v: tx.receiver, t: 'uint32' }, { v: tx.amount, t: 'uint32' });
}

function mapToPoint(tx: Tx) {
  const e = hash(tx);
  return mcl.g1ToHex(mcl.mapToPoint(e));
}

contract('Tx Serialization', accounts => {
  let c: TestTxInstance;
  before(async function() {
    await mcl.init();
    c = await TestTx.new();
  });
  it('parse transaction', async function() {
    const txSize = 128;
    const txs: Tx[] = [];
    for (let i = 0; i < txSize; i++) {
      const sender = web3.utils.hexToNumber(web3.utils.randomHex(senderLen));
      const receiver = web3.utils.hexToNumber(web3.utils.randomHex(receiverLen));
      const amount = web3.utils.hexToNumber(web3.utils.randomHex(amountLen));
      txs.push({ sender, receiver, amount });
    }
    const serialized = serialize(txs);
    assert.equal(txSize, (await c.size(serialized)).toNumber());
    assert.isFalse(await c.hasExcessData(serialized));
    for (let i = 0; i < txSize; i++) {
      let amount = (await c.amountOf(serialized, i)).toNumber();
      assert.equal(amount, txs[i].amount);
      let sender = (await c.senderOf(serialized, i)).toNumber();
      assert.equal(sender, txs[i].sender);
      let receiver = (await c.receiverOf(serialized, i)).toNumber();
      assert.equal(receiver, txs[i].receiver);
      let hash0 = hash(txs[i]);
      let hash1 = await c.hashOf(serialized, i);
      assert.equal(hash0, hash1);
      let p0 = await c.mapToPoint(serialized, i);
      let p1 = mapToPoint(txs[i]);
      assert.equal(p1[0], bnToHex(p0[0].toString(16)));
      assert.equal(p1[1], bnToHex(p0[1].toString(16)));
    }
  });
});
