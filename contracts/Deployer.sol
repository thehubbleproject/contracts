pragma solidity ^0.5.15;
import {ParamManager} from "./libs/ParamManager.sol";
import {NameRegistry as Registry} from "./NameRegistry.sol";
import {DepositManager} from "./DepositManager.sol";
import {TestToken} from "./TestToken.sol";
import {Rollup} from "./rollup.sol";
import {TokenRegistry} from "./TokenRegistry.sol";
import {Logger} from "./logger.sol";
import {MerkleTreeUtils as MTUtils} from "./MerkleTreeUtils.sol";
import {Governance} from "./Governance.sol";

// Deployer is supposed to deploy new set of contracts while setting up all the utilities
// libraries and other auxiallry contracts like registry
contract Deployer {
  constructor(
    address nameregistry,
    uint256 maxDepth,
    uint256 maxDepositSubTree
  ) public {
    deployContracts(nameregistry, maxDepth, maxDepositSubTree);
  }

  function deployContracts(
    address nameRegistryAddr,
    uint256 maxDepth,
    uint256 maxDepositSubTree
  ) public returns (address) {
    Registry registry = Registry(nameRegistryAddr);
    address governance = address(new Governance(maxDepth, maxDepositSubTree));
    require(registry.registerName(ParamManager.Governance(), governance), "Could not register governance");
    address mtUtils = address(new MTUtils(nameRegistryAddr));
    require(registry.registerName(ParamManager.MERKLE_UTILS(), mtUtils), "Could not register merkle utils tree");

    address logger = address(new Logger());
    require(registry.registerName(ParamManager.LOGGER(), logger), "Cannot register logger");

    address tokenRegistry = address(new TokenRegistry(nameRegistryAddr));
    require(registry.registerName(ParamManager.TOKEN_REGISTRY(), tokenRegistry), "Cannot register token registry");

    return nameRegistryAddr;
  }
}
