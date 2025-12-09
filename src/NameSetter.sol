// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameSetterUtils.sol";

/// @title NameSetter
/// @notice A library for setting ENS names via ENS core contracts
/// @dev This library provides functionality to create subnames and set forward resolution
library NameSetter {

    /// @notice Sets primary name for the given contract address. If primary name cannot be set, then sets only forward resolution.
    /// @dev Creates a subname under the parent node and sets the address record
    /// @param chainId The chain ID where the contract is deployed
    /// @param contractAddress The contract address to name
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    function setName(
        uint256 chainId,
        address contractAddress,
        string memory fullName
    ) internal returns (bool success) {
        (bool forwardSuccess, bytes32 node) = NameSetterUtils._setForwardResolutionInternal(chainId, contractAddress, fullName);
        require(forwardSuccess, "NameSetter: forward resolution failed");
        
        // After forward resolution succeeds, set reverse/primary name
        require(NameSetterUtils._setPrimaryName(chainId, contractAddress, node, fullName), "NameSetter: setPrimaryName failed");
        return true;
    }

    /// @notice Sets the ENS subname and forward resolution only (without reverse record)
    /// @dev Creates a subname under the parent node and sets the address record, but does not set reverse resolution
    /// @param chainId The chain ID to determine which ENS contracts to use
    /// @param contractAddress The contract address to set in the address record
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    function setForwardResolution(
        uint256 chainId,
        address contractAddress,
        string memory fullName
    ) internal returns (bool success) {
        (bool forwardSuccess,) = NameSetterUtils._setForwardResolutionInternal(chainId, contractAddress, fullName);
        require(forwardSuccess, "NameSetter: forward resolution failed");
        return forwardSuccess;
    }
}
