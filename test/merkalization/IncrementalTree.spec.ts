const MTLib = artifacts.require("MerkleTreeUtils");
const IMT = artifacts.require("IncrementalTree");
const nameRegistry = artifacts.require("NameRegistry");
const ParamManager = artifacts.require("ParamManager");
import * as walletHelper from "../helpers/wallet";
import * as utils from "../helpers/utils";
contract("IncrementalTree", async function(accounts) {
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
    fourthDataBlock
  ];
  var dataLeaves = [
    utils.Hash(firstDataBlock),
    utils.Hash(secondDataBlock),
    utils.Hash(thirdDataBlock),
    utils.Hash(fourthDataBlock)
  ];

  before(async function() {
    wallets = walletHelper.generateFirstWallets(walletHelper.mnemonics, 10);
  });

  // test if we are able to create append a leaf
  it("create incremental MT and add 2 leaves", async function() {
    var nameRegistryInstance = await nameRegistry.deployed();
    var paramManager = await ParamManager.deployed();
    var mtLibKey = await paramManager.MERKLE_UTILS();
    var MtUtilsAddr = await nameRegistryInstance.getContractDetails(mtLibKey);
    var mtlibInstance = await MTLib.at(MtUtilsAddr);
    let IMTInstace = await IMT.deployed();
    var leaf = dataLeaves[0];
    var zeroLeaf = await mtlibInstance.getRoot(0);
    console.log(await IMTInstace.appendLeaf.call(leaf));
    var root = await IMTInstace.getTreeRoot();
    var path = "00";
    var siblings = [zeroLeaf, utils.getParentLeaf(zeroLeaf, zeroLeaf)];
    var isValid = await mtlibInstance.verifyLeaf(root, leaf, path, siblings);
    expect(isValid).to.be.deep.eq(true);
    leaf = dataLeaves[1];
    await IMTInstace.appendLeaf(leaf);
    root = await IMTInstace.getTreeRoot();
    path = "01";
    var siblings2 = [dataLeaves[0], utils.getParentLeaf(zeroLeaf, zeroLeaf)];
    isValid = await mtlibInstance.verifyLeaf(root, leaf, path, siblings2);
    expect(isValid).to.be.deep.eq(true);
  });
});
