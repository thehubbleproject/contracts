import * as walletHelper from "../../scripts/helpers/wallet";
import * as migrateUtils from "../../scripts/helpers/migration";
import * as utils from "../../scripts/helpers/utils";
const BN = require("bn.js");

var argv = require('minimist')(process.argv.slice(2));

const ECVerifyLib = artifacts.require("ECVerify");
const paramManagerLib = artifacts.require("ParamManager");
const rollupUtilsLib = artifacts.require("RollupUtils");
const Types = artifacts.require("Types");

// Contracts Deployer
const governanceContract = artifacts.require("Governance");
const MTUtilsContract = artifacts.require("MerkleTreeUtils");
const incrementalTreeContract = artifacts.require("IncrementalTree");


const nameRegistryContract = artifacts.require("NameRegistry");

contract("IncrementalTree", async function (accounts) {
  var wallets: any;
  var depth: number = 2;
  var firstDataBlock = utils.StringToBytes32("0x123");
  var secondDataBlock = utils.StringToBytes32("0x334");
  var thirdDataBlock = utils.StringToBytes32("0x4343");
  var fourthDataBlock = utils.StringToBytes32("0x334");
  var dataBlocks = [
    firstDataBlock,
    secondDataBlock,
    thirdDataBlock,
    fourthDataBlock,
  ];
  var dataLeaves = [
    utils.Hash(firstDataBlock),
    utils.Hash(secondDataBlock),
    utils.Hash(thirdDataBlock),
    utils.Hash(fourthDataBlock),
  ];

  var coordinator = "0x9fB29AAc15b9A4B7F17c3385939b007540f4d791";
  var max_depth = 4;
  var maxDepositSubtreeDepth = 1;

  let paramManagerInstance: any;
  let nameRegistryInstance: any;
  let MTUtilsInstance: any;
  let IMTInstace: any;
  before(async function () {
    wallets = walletHelper.generateFirstWallets(walletHelper.mnemonics, 10);
    if (argv.dn) {
      const typesLib: any = await migrateUtils.deployAndUpdate("Types", {})
      const ECVerifyLibInstance: any = await migrateUtils.deployAndUpdate("ECVerify", {})
      const rollupUtilsLibInstance: any = await migrateUtils.deployAndUpdate("RollupUtils", {})
      paramManagerInstance = await migrateUtils.deployAndUpdate("ParamManager", {})
      nameRegistryInstance = await migrateUtils.deployAndUpdate("NameRegistry", {})
  
      let governanceInstance: any = await migrateUtils.deployAndUpdate("Governance", {}, [max_depth, maxDepositSubtreeDepth]);
  
      await nameRegistryInstance.registerName(
        await paramManagerInstance.Governance(),
        governanceInstance.address
      )
  
      let libLinksMTU = {
        "ECVerify" : ECVerifyLibInstance.address,
        "ParamManager": paramManagerInstance.address,
        "RollupUtils": rollupUtilsLibInstance.address,
        "Types": typesLib.address,
      }
      MTUtilsInstance = await migrateUtils.deployAndUpdate("MerkleTreeUtils", libLinksMTU, [nameRegistryInstance.address])
  
      await nameRegistryInstance.registerName(
        await paramManagerInstance.MERKLE_UTILS(),
        MTUtilsInstance.address
      )
  
      console.log("MTUtilsInstance.address:", MTUtilsInstance.address)
  
      let libLinksIMT = {
        "ParamManager": paramManagerInstance.address,
      }
      IMTInstace = await migrateUtils.deployAndUpdate("IncrementalTree", libLinksIMT, [nameRegistryInstance.address])
  
      await nameRegistryInstance.registerName(
        await paramManagerInstance.ACCOUNTS_TREE(),
        IMTInstace.address
      )
  
      console.log("IMTInstace.address:", IMTInstace.address)
    } else {
      IMTInstace = await incrementalTreeContract.deployed()
    }

  });

  // test if we are able to create append a leaf
  it("create incremental MT and add 2 leaves", async function () {
    // get mtlibInstance
    var mtlibInstance = await utils.getMerkleTreeUtils(nameRegistryInstance, paramManagerInstance);

    // get leaf to be inserted
    var leaf = dataLeaves[0];
    var coordinator =
      "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563";
    var zeroLeaf = await mtlibInstance.getRoot(0);
    var zeroLeaf1 = await mtlibInstance.getRoot(1);
    var zeroLeaf2 = await mtlibInstance.getRoot(2);
    var zeroLeaf3 = await mtlibInstance.getRoot(3);

    // append leaf to the tree
    await IMTInstace.appendLeaf(leaf);

    // validate if the leaf was inserted correctly
    var root = await IMTInstace.getTreeRoot();
    var path = "2";
    var siblings = [coordinator, zeroLeaf1, zeroLeaf2, zeroLeaf3];

    // call stateless merkle tree utils
    var isValid = await mtlibInstance.verifyLeaf(root, leaf, path, siblings);
    console.log("1")
    expect(isValid).to.be.deep.eq(true);
    console.log("2")

    // add another leaf to the tree
    leaf = dataLeaves[1];
    await IMTInstace.appendLeaf(leaf);
    var nextLeafIndex = await IMTInstace.nextLeafIndex();
    // verify that the new leaf was inserted correctly
    var root1 = await IMTInstace.getTreeRoot();

    var pathToSecondAccount = "3";
    var siblings2 = [
      dataLeaves[0],
      utils.getParentLeaf(coordinator, coordinator),
      zeroLeaf2,
      zeroLeaf3,
    ];
    isValid = await mtlibInstance.verifyLeaf(
      root1,
      leaf,
      pathToSecondAccount,
      siblings2
    );
    console.log("3")
    expect(isValid).to.be.deep.eq(true);
    console.log("4")

  });
});

/**
 * Converts a big number to a hex string.
 * @param bn the big number to be converted.
 * @returns the big number as a string.
 */
export const bnToHexString = (bn: BN): string => {
  return "0x" + bn.toString("hex");
};

/**
 * Converts a buffer to a hex string.
 * @param buf the buffer to be converted.
 * @returns the buffer as a string.
 */
export const bufToHexString = (buf: Buffer): string => {
  return "0x" + buf.toString("hex");
};