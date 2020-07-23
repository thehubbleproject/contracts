var fs = require('fs');

import * as utils from "../../scripts/helpers/utils";
import * as walletHelper from "../..//scripts/helpers/wallet";
import { assert } from "chai";
let RollupUtilContract = artifacts.require("RollupUtils");
const Types = artifacts.require("Types");

const truffleContract = require("@truffle/contract");
var Web3 = require('web3');
var provider = new Web3.providers.HttpProvider("http://localhost:8545");

contract("RollupUtils", async function (accounts) {
  
  var wallets: any;
  let rollupUtils: any;
  let rollupUtilsInstance: any;

  before(async function () {
    wallets = walletHelper.generateFirstWallets(walletHelper.mnemonics, 10);
    const typesLib = await Types.new();
    await RollupUtilContract.link("Types", typesLib.address);
    rollupUtilsInstance = await RollupUtilContract.new();
    var networkId = await web3.eth.net.getId()
    console.log("RollupUtilContractAddr: ", rollupUtilsInstance.address)
    await (new Promise(async (resolve, reject) => {
      fs.readFile('./build/contracts/RollupUtils.json', {encoding: 'utf8'}, (err: any,data:any) => {
        var users = JSON.parse(data);
        users.networks[networkId] = { 
          events: {},
          links: {},
          address: rollupUtilsInstance.address,
          transactionHash: rollupUtilsInstance.transactionHash 
        }
        var string = JSON.stringify(users, null, '\t');
        fs.writeFile('./build/contracts/RollupUtils.json', string, (err: any) => {
          if(err) return console.error(err);
          console.log('done');
          rollupUtils = truffleContract(users);
          rollupUtils.setProvider(provider);
          resolve("done")
        })
      })
    }).then(console.log))
    rollupUtils = await rollupUtils.deployed();
  });

  // test if we are able to create append a leaf
  /* it("test if account hash is correctly generated", async function () { */
  /*   var Alice = { */
  /*     Address: wallets[0].getAddressString(), */
  /*     Pubkey: wallets[0].getPublicKeyString(), */
  /*     Amount: 10, */
  /*     TokenType: 1, */
  /*     AccID: 1, */
  /*     Path: "0000", */
  /*     Nonce: 0, */
  /*   }; */

  /*   var AliceAccountLeaf = utils.CreateAccountLeaf( */
  /*     Alice.AccID, */
  /*     Alice.Amount, */
  /*     Alice.Nonce, */
  /*     Alice.TokenType */
  /*   ); */
  /*   var rollupUtils = await RollupUtils.deployed(); */
  /*   var data = { */
  /*     ID: Alice.AccID, */
  /*     tokenType: Alice.TokenType, */
  /*     balance: Alice.Amount, */
  /*     nonce: Alice.Nonce, */
  /*   }; */
  /*   var accountHash = await rollupUtils.getAccountHash( */
  /*     data.ID, */
  /*     data.balance, */
  /*     data.nonce, */
  /*     data.tokenType */
  /*   ); */
  /*   assert.equal(AliceAccountLeaf, accountHash, "Account hash mismatch"); */
  /* }); */
  // it("test if tx is correctly encoded to bytes and hash", async function () {
  //   var rollupUtils = await RollupUtils.deployed();
  //   var tx = {
  //     fromIndex: 1,
  //     toIndex: 2,
  //     tokenType: 1,
  //     amount: 1,
  //     signature:
  //       "0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563",
  //   };

  //   var expectedResult = utils.HashFromTx(
  //     tx.fromIndex,
  //     tx.toIndex,
  //     tx.tokenType,
  //     tx.amount
  //   );

  //   var result = await rollupUtils.getTxHash(
  //     tx.fromIndex,
  //     tx.toIndex,
  //     tx.tokenType,
  //     tx.amount
  //   );
  //   assert.equal(expectedResult, result, "Account hash mismatch");
  // });

  it("test account encoding and decoding", async function () {
    console.log(rollupUtils.address)
    var account = {
      ID: 1,
      tokenType: 2,
      balance: 3,
      nonce: 4,
    };

    var accountBytes = await rollupUtils.BytesFromAccountDeconstructed(
      account.ID,
      account.balance,
      account.nonce,
      account.tokenType
    );
    var regeneratedAccount = await rollupUtils.AccountFromBytes(accountBytes);
    assert.equal(regeneratedAccount["0"].toNumber(), account.ID);
    assert.equal(regeneratedAccount["1"].toNumber(), account.balance);
    assert.equal(regeneratedAccount["2"].toNumber(), account.nonce);
    assert.equal(regeneratedAccount["3"].toNumber(), account.tokenType);

    var tx = {
      fromIndex: 1,
      toIndex: 2,
      tokenType: 1,
      amount: 10,
      signature:
        "0x1ad4773ace8ee65b8f1d94a3ca7adba51ee2ca0bdb550907715b3b65f1e3ad9f69e610383dc9ceb8a50c882da4b1b98b96500bdf308c1bdce2187cb23b7d736f1b",
      txType: 1,
      nonce: 0,
    };

    var txBytes = await rollupUtils.BytesFromTxDeconstructed(
      tx.fromIndex,
      tx.toIndex,
      tx.tokenType,
      tx.nonce,
      tx.txType,
      tx.amount
    );

    var txData = await rollupUtils.TxFromBytes(txBytes);
    assert.equal(txData.fromIndex.toString(), tx.fromIndex.toString());
    assert.equal(txData.toIndex.toString(), tx.toIndex.toString());
    assert.equal(txData.tokenType.toString(), tx.tokenType.toString());
    assert.equal(txData.nonce.toString(), tx.nonce.toString());
    assert.equal(txData.txType.toString(), tx.txType.toString());
    assert.equal(txData.amount.toString(), tx.amount.toString());

    var compressedTx = await rollupUtils.CompressTxWithMessage(
      txBytes,
      tx.signature
    );

    var decompressedTx = await rollupUtils.DecompressTx(compressedTx);
    assert.equal(decompressedTx[0].toNumber(), tx.fromIndex);
    assert.equal(decompressedTx[1].toNumber(), tx.toIndex);
    assert.equal(decompressedTx[2].toNumber(), tx.amount);
    assert.equal(decompressedTx[3].toString(), tx.signature);
  });
});