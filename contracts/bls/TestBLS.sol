pragma solidity ^0.5.15;

import {BLS} from "./BLS.sol";

contract TestBLS {
    function gasCost() external returns (uint256) {
        uint256 g = gasleft();
        return g - gasleft();
    }

    function verifyMultiple(
        uint256[2] memory signature,
        uint256[2][2][] memory pubkeys,
        uint256[2][] memory messages
    ) public view returns (bool) {
        return BLS.verifyMultiple(signature, pubkeys, messages);
    }

    function verifyMultipleGasCost(
        uint256[2] memory signature,
        uint256[2][2][] memory pubkeys,
        uint256[2][] memory messages
    ) public returns (uint256) {
        uint256 g = gasleft();
        require(
            BLS.verifyMultiple(signature, pubkeys, messages),
            "BLSTest: expect succesful verification"
        );
        return g - gasleft();
    }

    function hashToPoint(bytes memory data)
        public
        view
        returns (uint256[2] memory p)
    {
        return BLS.hashToPoint(data);
    }

    function hashToPointGasCost(bytes memory data) public returns (uint256 p) {
        uint256 g = gasleft();
        BLS.hashToPoint(data);
        return g - gasleft();
    }

    function sqrt(uint256 a) public view returns (uint256 x, bool) {
        return BLS.sqrt(a);
    }
}
