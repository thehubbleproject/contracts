pragma solidity >=0.4.21;

import {Logger} from "./logger.sol";
import {NameRegistry as Registry} from "./NameRegistry.sol";
import {ParamManager} from "./libs/ParamManager.sol";
import {POB} from "./POB.sol";

contract SpokeRegistry {
    Logger public logger;
    Registry public nameRegistry;

    mapping(uint256 => address) public registeredSpokes;
    uint256 public numSpokes;

    constructor(address _registryAddr) public {
        nameRegistry = Registry(_registryAddr);
        logger = Logger(nameRegistry.getContractDetails(ParamManager.LOGGER()));
    }

    function registerSpoke(address spoke) public {
        numSpokes++;
        registeredSpokes[numSpokes] = spoke;
        logger.logSpokeRegistration(spoke, numSpokes);
    }
}
