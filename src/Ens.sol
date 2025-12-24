// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./L1NameSetter.sol";
import "./L2NameSetter.sol";
import "./CommonUtils.sol";

/// @title Ens
/// @notice A library for setting ENS names via ENS core contracts
/// @dev This library provides functionality to create subnames and set forward resolution
/// @dev Routes to L1NameSetter for L1 chains or L2NameSetter for L2 chains
library Ens {
    /// @notice Sets primary name for the given contract address. If primary name cannot be set, then sets only forward resolution.
    /// @dev Creates a subname under the parent node and sets the address record
    /// @param chainId The chain ID where the contract is deployed
    /// @param contractAddress The contract address to name
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    function setName(uint256 chainId, address contractAddress, string memory fullName)
        internal
        returns (bool success)
    {
        // Route to L2-specific logic for L2 chains
        if (
            chainId == CommonUtils.BASE_MAINNET || chainId == CommonUtils.BASE_SEPOLIA
                || chainId == CommonUtils.OPTIMISM_MAINNET || chainId == CommonUtils.OPTIMISM_SEPOLIA
                || chainId == CommonUtils.ARBITRUM_MAINNET || chainId == CommonUtils.ARBITRUM_SEPOLIA
                || chainId == CommonUtils.SCROLL_MAINNET || chainId == CommonUtils.SCROLL_SEPOLIA
        ) {
            return L2NameSetter.setName(chainId, contractAddress, fullName);
        } else {
            // Use L1 logic for other chains
            return L1NameSetter.setName(chainId, contractAddress, fullName);
        }
    }

    /// @notice Sets the ENS subname and forward resolution only (without reverse record)
    /// @dev Creates a subname under the parent node and sets the address record, but does not set reverse resolution
    /// @param chainId The chain ID to determine which ENS contracts to use
    /// @param contractAddress The contract address to set in the address record
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    function setForwardResolution(uint256 chainId, address contractAddress, string memory fullName)
        internal
        returns (bool success)
    {
        // Route to L2-specific logic for L2 chains
        if (
            chainId == CommonUtils.BASE_MAINNET || chainId == CommonUtils.BASE_SEPOLIA
                || chainId == CommonUtils.OPTIMISM_MAINNET || chainId == CommonUtils.OPTIMISM_SEPOLIA
                || chainId == CommonUtils.ARBITRUM_MAINNET || chainId == CommonUtils.ARBITRUM_SEPOLIA
                || chainId == CommonUtils.SCROLL_MAINNET || chainId == CommonUtils.SCROLL_SEPOLIA
        ) {
            (bool l2ForwardSuccess,) = L2NameSetter.setForwardResolution(chainId, contractAddress, fullName);
            require(l2ForwardSuccess, "Ens: forward resolution failed");
            return l2ForwardSuccess;
        } else {
            // Use L1 logic for other chains
            (bool l1ForwardSuccess,) = L1NameSetter.setForwardResolution(chainId, contractAddress, fullName);
            require(l1ForwardSuccess, "Ens: forward resolution failed");
            return l1ForwardSuccess;
        }
    }
}
