// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameSetterUtils.sol";

/// @title NameSetter
/// @notice A library for setting ENS names via ENS core contracts
/// @dev This library provides functionality to create subnames and set forward resolution
library NameSetter {

    /// @notice Sets the ENS subname and forward resolution for a contract address
    /// @dev Creates a subname under the parent node and sets the address record
    /// @param chainId The chain ID to determine which ENS contracts to use
    /// @param contractAddress The contract address to set in the address record
    /// @param fullName The full ENS name (e.g., "myname.eth")
    /// @return success Whether the operation succeeded
    function setName(
        uint256 chainId,
        address contractAddress,
        string calldata fullName
    ) internal returns (bool success) {
        (string memory label, string memory parentName) = NameSetterUtils.splitName(fullName);
        bytes32 parentNode = NameSetterUtils.namehash(parentName);
        bytes32 labelHash = keccak256(bytes(label));
        bytes32 node = keccak256(abi.encodePacked(parentNode, labelHash));

        require(NameSetterUtils._isSenderOwner(chainId, parentNode), "NameSetter: sender is not the owner of parent node");
        require(NameSetterUtils._createSubname(chainId, parentNode, label, labelHash), "NameSetter: subname creation failed");

        require(NameSetterUtils._setAddr(chainId, node, 60, abi.encodePacked(contractAddress)), "NameSetter: setAddr, forward resolution failed");
        // After forward resolution succeeds, set reverse/primary name using Enscribe-style helper
        require(NameSetterUtils._setPrimaryName(chainId, contractAddress, node, fullName), "NameSetter: setPrimaryName failed");
        return true;
    }
}
