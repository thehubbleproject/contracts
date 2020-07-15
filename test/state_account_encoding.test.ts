const TestStateAccount = artifacts.require('TestStateAccount');
import { TestStateAccountInstance } from '../types/truffle-contracts';

interface Account {
  accountIndex: number;
  tokenType: number;
  balance: number;
  nonce: number;
}

let accountIndexLen = 4;
let tokenTypeLen = 2;
let balanceLen = 4;
let nonceLen = 4;

function encodeAccount(acc: Account): string {
  let serialized = '0x';
  let accountIndex = web3.utils.padLeft(web3.utils.toHex(acc.accountIndex), accountIndexLen * 2);
  let tokenType = web3.utils.padLeft(web3.utils.toHex(acc.tokenType), tokenTypeLen * 2);
  let balance = web3.utils.padLeft(web3.utils.toHex(acc.balance), balanceLen * 2);
  let nonce = web3.utils.padLeft(web3.utils.toHex(acc.nonce), nonceLen * 2);
  serialized = web3.utils.padLeft(serialized + accountIndex.slice(2) + tokenType.slice(2) + balance.slice(2) + nonce.slice(2), 64);
  return serialized;
}

function decodeAccount(encoded: string): Account {
  if (encoded.slice(0, 2) == '0x') {
    assert.lengthOf(encoded, 66);
    encoded = encoded.slice(2);
  } else {
    assert.lengthOf(encoded, 64);
  }
  assert.isTrue(web3.utils.isHex(encoded));
  let t0 = 64 - nonceLen * 2;
  let t1 = 64;
  const nonce = web3.utils.hexToNumber('0x' + encoded.slice(t0, t1));
  t1 = t0;
  t0 = t0 - balanceLen * 2;
  const balance = web3.utils.hexToNumber('0x' + encoded.slice(t0, t1));
  t1 = t0;
  t0 = t0 - tokenTypeLen * 2;
  const tokenType = web3.utils.hexToNumber('0x' + encoded.slice(t0, t1));
  t1 = t0;
  t0 = t0 - accountIndexLen * 2;
  const accountIndex = web3.utils.hexToNumber('0x' + encoded.slice(t0, t1));
  return {
    accountIndex,
    tokenType,
    balance,
    nonce
  };
}

function hashAccount(acc: Account): string {
  return web3.utils.soliditySha3({ v: acc.accountIndex, t: 'uint32' }, { v: acc.tokenType, t: 'uint16' }, { v: acc.balance, t: 'uint32' }, { v: acc.nonce, t: 'uint32' });
}

contract('Tx Serialization', accounts => {
  let c: TestStateAccountInstance;
  const account0: Account = {
    accountIndex: 10,
    tokenType: 1,
    balance: 200,
    nonce: 8
  };
  before(async function() {
    c = await TestStateAccount.new();
  });
  it('encoding', async function() {
    const encoded = encodeAccount(account0);
    assert.equal(account0.accountIndex, (await c.accountID(encoded)).toNumber());
    assert.equal(account0.tokenType, (await c.tokenType(encoded)).toNumber());
    assert.equal(account0.balance, (await c.balance(encoded)).toNumber());
    assert.equal(account0.nonce, (await c.nonce(encoded)).toNumber());
    assert.equal(hashAccount(account0), await c.hash(encoded));
  });

  it('increment nonce', async function() {
    const encoded0 = encodeAccount(account0);
    const res = await c.incrementNonce(encoded0);
    assert.isTrue(res[1]);
    const encoded1 = web3.utils.padLeft(res[0].toString(16), 64);
    const account1 = decodeAccount(encoded1);
    assert.equal(account0.accountIndex, account1.accountIndex);
    assert.equal(account0.tokenType, account1.tokenType);
    assert.equal(account0.balance, account1.balance);
    assert.equal(account0.nonce + 1, account1.nonce);
  });

  it('balance safe add', async function() {
    const amount = 500;
    const encoded0 = encodeAccount(account0);
    const res = await c.balanceSafeAdd(encoded0, amount);
    assert.isTrue(res[1]);
    const encoded1 = web3.utils.padLeft(res[0].toString(16), 64);
    const account1 = decodeAccount(encoded1);
    assert.equal(account0.accountIndex, account1.accountIndex);
    assert.equal(account0.tokenType, account1.tokenType);
    assert.equal(account0.balance + amount, account1.balance);
    assert.equal(account0.nonce, account1.nonce);
    // TODO: test overflow
  });

  it('balance safe sub', async function() {
    const amount = 150;
    const encoded0 = encodeAccount(account0);
    const res = await c.balanceSafeSub(encoded0, amount);
    assert.isTrue(res[1]);
    const encoded1 = web3.utils.padLeft(res[0].toString(16), 64);
    const account1 = decodeAccount(encoded1);
    assert.equal(account0.accountIndex, account1.accountIndex);
    assert.equal(account0.tokenType, account1.tokenType);
    assert.equal(account0.balance - amount, account1.balance);
    assert.equal(account0.nonce, account1.nonce);
    // TODO: test overflow
  });
});
