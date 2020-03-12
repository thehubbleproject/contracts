pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract MerkleTreeLib{
    // The default hashes
    bytes32[160] public defaultHashes;

    /**
     * @notice Initialize a new MerkleTree contract, computing the default hashes for the merkle tree (MT)
     */
    constructor() public {
        // Calculate & set the default hashes
        setDefaultHashes();
    }

    /* Methods */
    /**
     * @notice Set default hashes
     */
    function setDefaultHashes() private {
        // Set the initial default hash.
        defaultHashes[0] = keccak256(abi.encodePacked(uint(0)));
        for (uint i = 1; i < defaultHashes.length; i ++) {
            defaultHashes[i] = keccak256(abi.encodePacked(defaultHashes[i-1], defaultHashes[i-1]));
        }
    }

    /**
     * @notice Get the merkle root computed from some set of data blocks.
     * @param _dataBlocks The data being used to generate the tree.
     * @return the merkle tree root
     * NOTE: This is a stateless operation
     */
    function getMerkleRoot(bytes[] calldata _dataBlocks) external view returns(bytes32) {
        uint nextLevelLength = _dataBlocks.length;
        uint currentLevel = 0;
        bytes32[] memory nodes = new bytes32[](nextLevelLength + 1); // Add one in case we have an odd number of leaves
        // Generate the leaves
        for (uint i = 0; i < _dataBlocks.length; i++) {
            nodes[i] = keccak256(_dataBlocks[i]);
        }
        if (_dataBlocks.length == 1) {
            return nodes[0];
        }
        // Add a defaultNode if we've got an odd number of leaves
        if (nextLevelLength % 2 == 1) {
            nodes[nextLevelLength] = defaultHashes[currentLevel];
            nextLevelLength += 1;
        }

        // Now generate each level
        while (nextLevelLength > 1) {
            currentLevel += 1;
            // Calculate the nodes for the currentLevel
            for (uint i = 0; i < nextLevelLength / 2; i++) {
                nodes[i] = getParent(nodes[i*2], nodes[i*2 + 1]);
            }
            nextLevelLength = nextLevelLength / 2;
            // Check if we will need to add an extra node
            if (nextLevelLength % 2 == 1 && nextLevelLength != 1) {
                nodes[nextLevelLength] = defaultHashes[currentLevel];
                nextLevelLength += 1;
            }
        }

        // Alright! We should be left with a single node! Return it...
        return nodes[0];
    }

    /**
     * @notice Calculate root from an inclusion proof.
     * @param _dataBlock The data block we're calculating root for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
    * NOTE: This is a stateless operation
     */
    function computeInclusionProofRoot(bytes memory _dataBlock, uint _path, bytes32[] memory _siblings) public pure returns (bytes32) {
        // First compute the leaf node
        bytes32 computedNode = keccak256(_dataBlock);
        for (uint i = 0; i < _siblings.length; i++) {
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                computedNode = getParent(computedNode, sibling);
            } else {
                computedNode = getParent(sibling, computedNode);
            }
        }
        // Check if the computed node (_root) is equal to the provided root
        return computedNode;
    }

    /**
     * @notice Calculate root from an inclusion proof.
     * @param _leaf The data block we're calculating root for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
    * NOTE: This is a stateless operation
     */
    function computeInclusionProofRootWithLeaf(bytes32 _leaf, uint _path, bytes32[] memory _siblings) public pure returns (bytes32) {
        // First compute the leaf node
        bytes32 computedNode = _leaf;
        for (uint i = 0; i < _siblings.length; i++) {
            bytes32 sibling = _siblings[i];
            uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
            if (isComputedRightSibling == 0) {
                computedNode = getParent(computedNode, sibling);
            } else {
                computedNode = getParent(sibling, computedNode);
            }
        }
        // Check if the computed node (_root) is equal to the provided root
        return computedNode;
    }

    /**
     * @notice Verify an inclusion proof.
     * @param _root The root of the tree we are verifying inclusion for.
     * @param _dataBlock The data block we're verifying inclusion for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
          * NOTE: This is a stateless operation

     */
    function verify(bytes32 _root, bytes memory _dataBlock, uint _path, bytes32[] memory _siblings) public pure returns (bool) {
        // First compute the leaf node
        bytes32 calculatedRoot = computeInclusionProofRoot(
            _dataBlock,
            _path,
            _siblings
        );
        return calculatedRoot == _root;
    }

    /**
     * @notice Verify an inclusion proof.
     * @param _root The root of the tree we are verifying inclusion for.
     * @param _leaf The data block we're verifying inclusion for.
     * @param _path The path from the leaf to the root.
     * @param _siblings The sibling nodes along the way.
     * @return The next level of the tree
          * NOTE: This is a stateless operation

     */
    function verifyLeaf(bytes32 _root, bytes32 _leaf, uint _path, bytes32[] memory _siblings) public pure returns (bool){
        bytes32 calculatedRoot = computeInclusionProofRootWithLeaf(
            _leaf,
            _path,
            _siblings
        );
        return calculatedRoot == _root;
    }

    /**
     * @notice Update a leaf using siblings and root
     *         This is a stateless operation
     * @param _leaf The leaf we're updating.
     * @param _path The path from the leaf to the root / the index of the leaf.
     * @param _root Initial root of the tree
     * @param _siblings The sibling nodes along the way.
     * @return Updated root
     */
    function updateLeafWithSiblings(bytes32 _leaf,uint _path,bytes32 _root,bytes32[] memory _siblings) public returns(bytes32) {
            bytes32 computedNode = _leaf;
            for (uint i = 0; i < _siblings.length; i++) {
                bytes32 parent;
                bytes32 sibling = _siblings[i];
                uint8 isComputedRightSibling = getNthBitFromRight(_path, i);
                if (isComputedRightSibling == 0) {
                    parent = getParent(computedNode, sibling);
                } else {
                    parent = getParent(sibling, computedNode);
                }
                computedNode = parent;
            }
            return computedNode;
    }


    /**
     * @notice Get the parent of two children nodes in the tree
     * @param _left The left child
     * @param _right The right child
     * @return The parent node
     */
    function getParent(bytes32 _left, bytes32 _right)public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_left, _right));
    }

    /**
     * @notice get the n'th bit in a uint.
     *         For instance, if exampleUint=binary(11), getNth(exampleUint, 0) == 1, getNth(2, 1) == 1
     * @param _intVal The uint we are extracting a bit out of
     * @param _index The index of the bit we want to extract
     * @return The bit (1 or 0) in a uint8
     */
    function getNthBitFromRight(uint _intVal, uint _index) public pure returns (uint8) {
        return uint8(_intVal >> _index & 1);
    }


    /**
     * @notice Get the right sibling key. Note that these keys overwrite the first bit of the hash
               to signify if it is on the right side of the parent or on the left
     * @param _parent The parent node
     * @return the key for the left sibling (0 as the first bit)
     */
    function getLeftSiblingKey(bytes32 _parent) public pure returns(bytes32) {
        return _parent & 0x0111111111111111111111111111111111111111111111111111111111111111;
    }

    /**
     * @notice Get the right sibling key. Note that these keys overwrite the first bit of the hash
               to signify if it is on the right side of the parent or on the left
     * @param _parent The parent node
     * @return the key for the right sibling (1 as the first bit)
     */
    function getRightSiblingKey(bytes32 _parent) public pure returns(bytes32) {
        return _parent | 0x1000000000000000000000000000000000000000000000000000000000000000;
    }


}