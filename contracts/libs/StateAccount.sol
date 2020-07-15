pragma solidity ^0.5.15;

library StateAccount {
  // account: [zeros<18>|account_index<4>|token_type<2>|balance<4>|nonce<4>]
  uint256 public constant ACCOUNT_LEN = 14;
  uint256 public constant ACCOUNT_OFF = 18; // word_size - ACCOUNT_LEN;
  // positions in bits
  uint256 public constant POSITION_ACCOUNT_INDEX = 80;
  uint256 public constant POSITION_TOKEN_TYPE = 64;
  uint256 public constant POSITION_BALANCE = 32;
  uint256 public constant POSITION_NONCE = 0;
  // masks
  uint256 public constant MASK_ACCOUNT_INDEX = 0xffffffff;
  uint256 public constant MASK_TOKEN_TYPE = 0xffff;
  uint256 public constant MASK_BALANCE = 0xffffffff;
  uint256 public constant MASK_NONCE = 0xffffffff;
  uint256 public constant MASK_NONCE_IN_PLACE = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000;
  uint256 public constant MASK_BALANCE_IN_PLACE = 0xffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffffff;

  function accountID(uint256 account) internal pure returns (uint256) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    return (account >>= POSITION_ACCOUNT_INDEX) & MASK_ACCOUNT_INDEX;
  }

  function tokenType(uint256 account) internal pure returns (uint256) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    return (account >>= POSITION_TOKEN_TYPE) & MASK_TOKEN_TYPE;
  }

  function balance(uint256 account) internal pure returns (uint256) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    return (account >>= POSITION_BALANCE) & MASK_BALANCE;
  }

  function nonce(uint256 account) internal pure returns (uint256) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    return (account >>= POSITION_NONCE) & MASK_NONCE;
  }

  function incrementNonce(uint256 account) internal pure returns (uint256, bool) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    uint256 _nonce = ((account >>= POSITION_NONCE) & MASK_NONCE);
    bool safe = _nonce < 0xffffffff; // require(_nonce < 0xffffffff, "nonce overflow");
    return (account + 1, safe);
  }

  function balanceSafeAdd(uint256 account, uint256 amount) internal pure returns (uint256, bool) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    uint256 _balance = (account >> POSITION_BALANCE) & MASK_BALANCE;
    uint256 newBalance = _balance + (amount & MASK_BALANCE);
    bool safe = newBalance <= 0xffffffff; // require(newBalance <= 0xffffffff, "balance addition overflow");
    return ((account & MASK_BALANCE_IN_PLACE) | (newBalance << POSITION_BALANCE), safe);
  }

  function balanceSafeSub(uint256 account, uint256 amount) internal pure returns (uint256, bool) {
    require(account < (1 << (ACCOUNT_LEN * 8)), "excess data");
    uint256 _balance = (account >> POSITION_BALANCE) & MASK_BALANCE;
    bool safe = _balance >= amount; // require(_balance >= amount, "subtraction overflow");
    uint256 newBalance = _balance - amount;
    return ((account & MASK_BALANCE_IN_PLACE) | (newBalance << POSITION_BALANCE), safe);
  }

  function hash(uint256 account) internal pure returns (bytes32 res) {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let mem := mload(0x40)
      mstore(mem, account)
      res := keccak256(add(mem, ACCOUNT_OFF), ACCOUNT_LEN)
    }
  }
}
