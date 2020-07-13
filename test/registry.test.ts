// const AccountRegistry = artifacts.require('BLSAccountRegistry');
// import { BLSAccountRegistryInstance } from '../types/truffle-contracts';
// import { Tree, Hasher } from './tree';

// import * as mcl from './mcl';

// let DEPTH: number;
// let BATCH_DEPTH: number;
// let hasher: Hasher;

// type Pubkey = mcl.mclG2;

// function pubkeyToLeaf(p: Pubkey) {
//   const compressed = mcl.compressPubkey(p);
//   const leaf = hasher.hash2(compressed[0], compressed[1]);
//   return { compressed, leaf };
// }

// contract('Registry', (accounts) => {
//   let registry: BLSAccountRegistryInstance;
//   let treeLeft: Tree;
//   let treeRight: Tree;
//   beforeEach(async function () {
//     await mcl.init();
//     registry = await AccountRegistry.new();
//     DEPTH = (await registry.DEPTH()).toNumber();
//     BATCH_DEPTH = (await registry.BATCH_DEPTH()).toNumber();
//     treeLeft = Tree.new(DEPTH);
//     treeRight = Tree.new(DEPTH);
//     hasher = treeLeft.hasher;
//   });

//   it('register a public keys', async function () {
//     for (let i = 0; i < 33; i++) {
//       const { pubkey } = mcl.newKeyPair();
//       const { compressed, leaf } = pubkeyToLeaf(pubkey);
//       treeLeft.updateSingle(i, leaf);
//       await registry.register(compressed);
//     }
//     assert.equal(treeLeft.root, await registry.rootLeft());
//     assert.equal(treeRight.root, await registry.rootRight());
//     const root = hasher.hash2(treeLeft.root, treeRight.root);
//     assert.equal(root, await registry.root());
//   });
//   it('batch update', async function () {
//     const batchSize = 1 << BATCH_DEPTH;
//     for (let k = 0; k < 4; k++) {
//       let leafs = [];
//       let pubkeys = [];
//       for (let i = 0; i < batchSize; i++) {
//         const { pubkey } = mcl.newKeyPair();
//         const { compressed, leaf } = pubkeyToLeaf(pubkey);
//         leafs.push(leaf);
//         pubkeys.push(compressed);
//       }
//       treeRight.updateBatch(batchSize * k, leafs);
//       await registry.registerBatch(pubkeys);
//       assert.equal(treeRight.root, await registry.rootRight());
//       const root = hasher.hash2(treeLeft.root, treeRight.root);
//       assert.equal(root, await registry.root());
//     }
//   });
//   it('exists', async function () {
//     let leafs = [];
//     let pubkeys = [];
//     for (let i = 0; i < 16; i++) {
//       const { pubkey } = mcl.newKeyPair();
//       const { compressed, leaf } = pubkeyToLeaf(pubkey);
//       leafs.push(leaf);
//       pubkeys.push(pubkey);
//       treeLeft.updateSingle(i, leaf);
//       await registry.register(compressed);
//     }
//     for (let i = 0; i < 16; i++) {
//       const leafIndex = i;
//       const pubkey = pubkeys[i];
//       const compressed = mcl.compressPubkey(pubkey);
//       const witness = treeLeft.witness(leafIndex).nodes;
//       const exist = await registry.compressedExists(compressed, leafIndex, witness);
//       assert.isTrue(exist, 'A');
//     }
//     for (let i = 0; i < 16; i++) {
//       const leafIndex = i;
//       const uncompressed = mcl.g2ToHex(pubkeys[i]);
//       const witness = treeLeft.witness(leafIndex).nodes;
//       const exist = await registry.uncompressedExists(uncompressed, leafIndex, witness);
//       assert.isTrue(exist, i.toString());
//     }
//   });
// });

const AccountRegistry = artifacts.require('BLSAccountRegistry');
import { BLSAccountRegistryInstance } from '../types/truffle-contracts';
import { Tree, Hasher } from './tree';

import * as mcl from './mcl';

let DEPTH: number;
let BATCH_DEPTH: number;
let hasher: Hasher;

type Pubkey = mcl.mclG2;

function pubkeyToLeaf(p: Pubkey) {
  const uncompressed = mcl.g2ToHex(p);
  const leaf = web3.utils.soliditySha3(
    { t: 'uint256', v: uncompressed[0] },
    { t: 'uint256', v: uncompressed[1] },
    { t: 'uint256', v: uncompressed[2] },
    { t: 'uint256', v: uncompressed[3] }
  );
  return { uncompressed, leaf };
}

contract('Registry', accounts => {
  let registry: BLSAccountRegistryInstance;
  let treeLeft: Tree;
  let treeRight: Tree;
  beforeEach(async function() {
    await mcl.init();
    registry = await AccountRegistry.new();
    DEPTH = (await registry.DEPTH()).toNumber();
    BATCH_DEPTH = (await registry.BATCH_DEPTH()).toNumber();
    treeLeft = Tree.new(DEPTH);
    treeRight = Tree.new(DEPTH);
    hasher = treeLeft.hasher;
  });

  it('register a public keys', async function() {
    for (let i = 0; i < 33; i++) {
      const { pubkey } = mcl.newKeyPair();
      const { uncompressed, leaf } = pubkeyToLeaf(pubkey);
      treeLeft.updateSingle(i, leaf);
      await registry.register(uncompressed);
    }
    assert.equal(treeLeft.root, await registry.rootLeft());
    assert.equal(treeRight.root, await registry.rootRight());
    const root = hasher.hash2(treeLeft.root, treeRight.root);
    assert.equal(root, await registry.root());
  });
  it('batch update', async function() {
    const batchSize = 1 << BATCH_DEPTH;
    for (let k = 0; k < 4; k++) {
      let leafs = [];
      let pubkeys = [];
      for (let i = 0; i < batchSize; i++) {
        const { pubkey } = mcl.newKeyPair();
        const { uncompressed, leaf } = pubkeyToLeaf(pubkey);
        leafs.push(leaf);
        pubkeys.push(uncompressed);
      }
      treeRight.updateBatch(batchSize * k, leafs);
      await registry.registerBatch(pubkeys);
      assert.equal(treeRight.root, await registry.rootRight());
      const root = hasher.hash2(treeLeft.root, treeRight.root);
      assert.equal(root, await registry.root());
    }
  });
  it('exists', async function() {
    let leafs = [];
    let pubkeys = [];
    for (let i = 0; i < 16; i++) {
      const { pubkey } = mcl.newKeyPair();
      const { uncompressed, leaf } = pubkeyToLeaf(pubkey);
      leafs.push(leaf);
      pubkeys.push(pubkey);
      treeLeft.updateSingle(i, leaf);
      await registry.register(uncompressed);
    }
    for (let i = 0; i < 16; i++) {
      const leafIndex = i;
      const uncompressed = mcl.g2ToHex(pubkeys[i]);
      const witness = treeLeft.witness(leafIndex).nodes;
      const exist = await registry.exists(uncompressed, leafIndex, witness);
      assert.isTrue(exist);
    }
  });
});
