pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import {ITokenRegistry} from "./interfaces/ITokenRegistry.sol";

import {Types} from "./libs/Types.sol";
import {Tx} from "./libs/Tx.sol";
import {RollupUtils} from "./libs/RollupUtils.sol";
import {ParamManager} from "./libs/ParamManager.sol";

import {MerkleTreeUtils as MTUtils} from "./MerkleTreeUtils.sol";
import {Governance} from "./Governance.sol";
import {NameRegistry as Registry} from "./NameRegistry.sol";

contract FraudProofSetup {
  using SafeMath for uint256;
  MTUtils public merkleUtils;
  ITokenRegistry public tokenRegistry;
  Registry public nameRegistry;
  bytes32 public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
  Governance public governance;
}

contract FraudProofHelpers is FraudProofSetup {
  function ValidateAccountMP(
    bytes32 root,
    uint256 stateID,
    Types.UserAccount memory account,
    bytes32[] memory witness
  ) public view {
    bytes32 accountLeaf = RollupUtils.getAccountHash(account.ID, account.balance, account.nonce, account.tokenType);
    require(merkleUtils.verifyLeaf(root, accountLeaf, stateID, witness), "Merkle Proof is incorrect");
  }

  function validateTxBasic(Types.Transaction memory _tx, Types.UserAccount memory _from_account)
    public
    view
    returns (Types.ErrorCode)
  {
    // verify that tokens are registered
    if (tokenRegistry.registeredTokens(_tx.tokenType) == address(0)) {
      // invalid state transition
      // to be slashed because the submitted transaction
      // had invalid token type
      return Types.ErrorCode.InvalidTokenAddress;
    }

    if (_tx.amount == 0) {
      // invalid state transition
      // needs to be slashed because the submitted transaction
      // had 0 amount.
      return Types.ErrorCode.InvalidTokenAmount;
    }

    // check from leaf has enough balance
    if (_from_account.balance < _tx.amount) {
      // invalid state transition
      // needs to be slashed because the account doesnt have enough balance
      // for the transfer
      return Types.ErrorCode.NotEnoughTokenBalance;
    }

    return Types.ErrorCode.NoError;
  }

  function RemoveTokensFromAccount(Types.UserAccount memory account, uint256 numOfTokens)
    public
    pure
    returns (Types.UserAccount memory updatedAccount)
  {
    return (RollupUtils.UpdateBalanceInAccount(account, RollupUtils.BalanceFromAccount(account).sub(numOfTokens)));
  }

  /**
   * @notice ApplyTx applies the transaction on the account. This is where
   * people need to define the logic for the application
   * @param _merkle_proof contains the siblings and path to the account
   * @param transaction is the transaction that needs to be applied
   * @return returns updated account and updated state root
   * */
  function ApplyTx(Types.AccountMerkleProof memory _merkle_proof, Types.Transaction memory transaction)
    public
    view
    returns (bytes memory updatedAccount, bytes32 newRoot)
  {
    Types.UserAccount memory account = _merkle_proof.accountIP.account;
    if (transaction.fromIndex == account.ID) {
      account = RemoveTokensFromAccount(account, transaction.amount);
      account.nonce++;
    }

    if (transaction.toIndex == account.ID) {
      account = AddTokensToAccount(account, transaction.amount);
    }

    newRoot = UpdateAccountWithSiblings(account, _merkle_proof);

    return (RollupUtils.BytesFromAccount(account), newRoot);
  }

  function AddTokensToAccount(Types.UserAccount memory account, uint256 numOfTokens)
    public
    pure
    returns (Types.UserAccount memory updatedAccount)
  {
    return (RollupUtils.UpdateBalanceInAccount(account, RollupUtils.BalanceFromAccount(account).add(numOfTokens)));
  }

  /**
   * @notice Returns the updated root and balance
   */
  function UpdateAccountWithSiblings(
    Types.UserAccount memory new_account,
    Types.AccountMerkleProof memory _merkle_proof
  ) public view returns (bytes32) {
    bytes32 newRoot = merkleUtils.updateLeafWithSiblings(
      keccak256(RollupUtils.BytesFromAccount(new_account)),
      _merkle_proof.accountIP.pathToAccount,
      _merkle_proof.siblings
    );
    return (newRoot);
  }
}

contract FraudProof is FraudProofHelpers {
  using Tx for bytes;

  /*********************
   * Constructor *
   ********************/
  constructor(address _registryAddr) public {
    nameRegistry = Registry(_registryAddr);

    governance = Governance(nameRegistry.getContractDetails(ParamManager.Governance()));

    merkleUtils = MTUtils(nameRegistry.getContractDetails(ParamManager.MERKLE_UTILS()));

    tokenRegistry = ITokenRegistry(nameRegistry.getContractDetails(ParamManager.TOKEN_REGISTRY()));
  }

  function generateTxRoot(bytes memory _txs) public view returns (bytes32 txRoot) {
    merkleUtils.calculateRootTruncated(_txs.toLeafs());
  }

  /**
   * @notice processBatch processes a whole batch
   * @return returns updatedRoot, txRoot and if the batch is valid or not
   * */
  function processBatch(
    bytes32 stateRoot,
    bytes memory txs,
    Types.InvalidTransitionProof memory proof
  ) public view returns (bytes32, bool) {
    bool isTxValid;
    uint256 batchSize = txs.size();
    require(batchSize > 0, "Rollup: empty batch");
    require(!txs.hasExcessData(), "Rollup: excess tx data");
    bytes32 acc = stateRoot;
    for (uint256 i = 0; i < batchSize; i++) {
      // A. check sender inclusion in state
      uint256 senderID = txs.senderOf(i);
      ValidateAccountMP(acc, senderID, proof.senderAccounts[i], proof.senderWitnesses[i]);
      // FIX: cannot be an empty account
      // if (proof.senderAccounts[i].isEmptyAccount()) {
      //   return bytes32(0), false;
      // }
      // B. apply diff for sender
      uint256 amount = txs.amountOf(i);
      Types.UserAccount memory account = proof.senderAccounts[i];
      if (account.balance < amount) {
        return (bytes32(0), false);
      }
      account.balance -= amount;
      account.nonce += 1;
      if (account.nonce >= 0x100000000) {
        return (bytes32(0), false);
      }
      acc = merkleUtils.updateLeafWithSiblings(
        keccak256(RollupUtils.BytesFromAccount(account)),
        senderID,
        proof.senderWitnesses[i]
      );
      // A. check receiver inclusion in state
      uint256 receiverID = txs.receiverOf(i);
      ValidateAccountMP(acc, receiverID, proof.receiverAccounts[i], proof.receiverWitnesses[i]);
      // FIX: cannot be an empty account
      // if (proof.receiverAccounts[i].isEmptyAccount()) {
      //   return bytes32(0), false;
      // }
      account = proof.senderAccounts[i];
      account.balance -= amount;
      if (account.balance >= 0x100000000) {
        return (bytes32(0), false);
      }
      acc = merkleUtils.updateLeafWithSiblings(
        keccak256(RollupUtils.BytesFromAccount(account)),
        senderID,
        proof.senderWitnesses[i]
      );
    }
    return (stateRoot, !isTxValid);
  }
}
