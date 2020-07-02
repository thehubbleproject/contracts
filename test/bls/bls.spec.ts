import {TestBLSInstance} from "../../types/truffle-contracts";

const BLSTestContract = artifacts.require("TestBLS");

const mcl = require("mcl-wasm");
const chai = require("chai");
const assert = chai.assert;

const FIELD_ORDER = web3.utils.toBN(
  "0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47"
);

function hashToPoint(data: string) {
  const e0 = web3.utils.toBN(web3.utils.soliditySha3(data));
  let e1 = new mcl.Fp();
  e1.setStr(e0.mod(FIELD_ORDER).toString());
  return e1.mapToG1();
}

function hex(p: any) {
  const arr = p.serialize();
  let s = "";
  for (let i = arr.length - 1; i >= 0; i--) {
    s += ("0" + arr[i].toString(16)).slice(-2);
  }
  return s;
}

function bn(n: string) {
  return web3.utils.toBN("0x" + n);
}

function mclG2ToBN(p: any) {
  p.normalize();
  const x = hex(p.getX());
  const y = hex(p.getY());
  return [
    [bn(x.slice(64)), bn(x.slice(0, 64))],
    [bn(y.slice(64)), bn(y.slice(0, 64))]
  ];
}

function mclG1ToBN(p: any) {
  p.normalize();
  const x = hex(p.getX());
  const y = hex(p.getY());
  return [bn(x), bn(y)];
}

function randFr() {
  const r = web3.utils.randomHex(12);
  let fr = new mcl.Fr();
  fr.setHashOf(r);
  return fr;
}

function g1() {
  const g1 = new mcl.G1();
  g1.setStr("1 0x01 0x02", 16);
  return g1;
}

function g2() {
  const g2 = new mcl.G2();
  g2.setStr(
    "1 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b"
  );
  return g2;
}

contract("BLS Library", accounts => {
  let bls: TestBLSInstance;
  before(async function() {
    await mcl.init(mcl.BN_SNARK1);
    mcl.setMapToMode(1);
    bls = await BLSTestContract.new();
  });
  it("hash to point", async function() {
    for (let i = 0; i < 50; i++) {
      const data = web3.utils.randomHex(12);
      let expect = hashToPoint(data);
      let res = await bls.hashToPoint(data);
      assert.equal(expect.getX().getStr(16), res[0].toString(16));
      assert.equal(expect.getY().getStr(16), res[1].toString(16));
    }
  });
  it.skip("hash to point gas cost", async function() {
    const n = 50;
    let totalCost = 0;
    for (let i = 0; i < n; i++) {
      const data = web3.utils.randomHex(12);
      let cost = await bls.hashToPointGasCost.call(data);
      totalCost += cost.toNumber();
    }
    console.log(`hash to point average cost: ${totalCost / n}`);
  });
  it("verify signature", async function() {
    const l = 10;
    const messages = [];
    const pubkeys = [];
    let aggSignature = new mcl.G1();
    for (let i = 0; i < l; i++) {
      const message = web3.utils.randomHex(12);
      const secret = randFr();
      const pubkey = mcl.mul(g2(), secret);
      const M = hashToPoint(message);
      const signature = mcl.mul(M, secret);
      aggSignature = mcl.add(aggSignature, signature);
      messages.push(M);
      pubkeys.push(pubkey);
    }
    let messages_ser = messages.map(p => mclG1ToBN(p));
    let pubkeys_ser = pubkeys.map(p => mclG2ToBN(p));
    let sig_ser = mclG1ToBN(aggSignature);
    let res = await bls.verifyMultiple(sig_ser, pubkeys_ser, messages_ser);
    assert.isTrue(res);
  });
  it.skip("verify signature gas cost", async function() {
    const n = 100;
    const messages = [];
    const pubkeys = [];
    let aggSignature = new mcl.G1();
    for (let i = 0; i < n; i++) {
      const message = web3.utils.randomHex(12);
      const secret = randFr();
      const pubkey = mcl.mul(g2(), secret);
      const M = hashToPoint(message);
      const signature = mcl.mul(M, secret);
      aggSignature = mcl.add(aggSignature, signature);
      messages.push(M);
      pubkeys.push(pubkey);
    }
    let messages_ser = messages.map(p => mclG1ToBN(p));
    let pubkeys_ser = pubkeys.map(p => mclG2ToBN(p));
    let sig_ser = mclG1ToBN(aggSignature);
    let cost = await bls.verifyMultipleGasCost.call(
      sig_ser,
      pubkeys_ser,
      messages_ser
    );
    console.log(`verify signature for ${n} message: ${cost.toNumber()}`);
  });
});
