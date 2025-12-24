// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommonUtils.sol";

/// @title L2NameSetter
/// @notice Library for setting L2 names for contracts according to ENSIP-19
/// @dev Handles subname creation, forward resolution, and reverse resolution for L2 chains
library L2NameSetter {
    /// @notice Sets name for L2 chains with ENSIP-19
    /// @dev Creates a subname, sets forward resolution, sets reverse/primary name
    /// @param chainId The chain ID
    /// @param contractAddress The contract address to name
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    function setName(uint256 chainId, address contractAddress, string memory fullName)
        internal
        returns (bool success)
    {
        require(contractAddress != address(0), "Ens: contractAddress cannot be zero");
        // Step 1: Create subname and set forward resolution
        (bool forwardSuccess, bytes32 node) = setForwardResolution(chainId, contractAddress, fullName);
        require(forwardSuccess, "Ens: forward resolution failed");

        // Step 2: Set reverse/primary name
        require(setReverseResolution(chainId, contractAddress, node, fullName), "Ens: setReverseResolution failed");

        return true;
    }

    /// @notice Creates ENS subname under given parent
    /// @dev Uses msg.sender as the owner of the created subname
    /// @dev According to ENSIP-10: uses resolver from parent node, falls back to public resolver if none set
    /// @param chainId The chain ID
    /// @param parentNode The parent node
    /// @param labelHash The hash of the label
    /// @return success Whether the operation succeeded
    function createSubname(uint256 chainId, bytes32 parentNode, bytes32 labelHash) internal returns (bool success) {
        address registry = CommonUtils.getRegistry(chainId);
        address publicResolver = CommonUtils.getPublicResolver(chainId);

        require(registry != address(0), "Ens: unsupported chainId");
        require(publicResolver != address(0), "Ens: public resolver not set for chain");

        // Get resolver from parent node according to ENSIP-10
        address resolver = IENSRegistry(registry).resolver(parentNode);
        // If no resolver is set for parent node, use public resolver as fallback
        if (resolver == address(0)) {
            resolver = publicResolver;
        }

        // Compute the subname node
        bytes32 subnameNode = keccak256(abi.encodePacked(parentNode, labelHash));

        // Check if subname already exists
        address existingOwner = IENSRegistry(registry).owner(subnameNode);
        bool subnameExists = (existingOwner != address(0));

        // If subname exists and we own it, skip creation
        if (subnameExists && existingOwner == msg.sender) {
            return true;
        }

        // If subname exists but we don't own it, revert
        require(!subnameExists, "Ens: subname already exists and is owned by another address");

        // Create subname using L2 registry with resolver from parent node (or public resolver fallback)
        IENSRegistry(registry).setSubnodeRecord(parentNode, labelHash, msg.sender, resolver, 0);
        return true;
    }

    /// @notice Checks if address record already exists and matches the target address
    /// @param resolverAddr The resolver address to use
    /// @param node The ENS node
    /// @param coinType The coin type (60 for ETH)
    /// @param targetAddrBytes The target address as bytes
    /// @return matches Whether the existing address matches the target
    function addrMatches(address resolverAddr, bytes32 node, uint256 coinType, bytes memory targetAddrBytes)
        internal
        view
        returns (bool matches)
    {
        if (resolverAddr == address(0)) {
            return false;
        }

        try IPublicResolver(resolverAddr).addr(node, coinType) returns (bytes memory existingAddrBytes) {
            return keccak256(existingAddrBytes) == keccak256(targetAddrBytes);
        } catch {
            return false;
        }
    }

    /// @notice Sets address record, forward resolution
    /// @param resolverAddr The resolver address to use
    /// @param node The ENS node
    /// @param coinType The coin type (60 for ETH)
    /// @param addrBytes The address as bytes
    /// @return success Whether the operation succeeded
    function setAddr(address resolverAddr, bytes32 node, uint256 coinType, bytes memory addrBytes)
        internal
        returns (bool success)
    {
        // Check if address record already exists and matches
        if (addrMatches(resolverAddr, node, coinType, addrBytes)) {
            return true; // Already set correctly, skip
        }

        require(resolverAddr != address(0), "Ens: resolver not set for node");

        try IPublicResolver(resolverAddr).setAddr(node, coinType, addrBytes) {
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Checks if reverse/primary name already exists and matches the target name
    /// @param chainId The chain ID
    /// @param addr The address to check
    /// @param targetName The target name to compare against
    /// @return matches Whether the existing name matches the target
    function primaryNameMatches(uint256 chainId, address addr, string memory targetName)
        internal
        view
        returns (bool matches)
    {
        // Get the L2 reverse registrar for the chain
        address reverseRegistrar = CommonUtils.getReverseRegistrar(chainId);
        if (reverseRegistrar == address(0)) {
            return false;
        }

        // Call nameForAddr on the L2 reverse registrar
        try IL2ReverseRegistrar(reverseRegistrar).nameForAddr(addr) returns (string memory existingName) {
            // Compare the returned name with the target name
            return keccak256(bytes(existingName)) == keccak256(bytes(targetName));
        } catch {
            return false;
        }
    }

    /// @notice Sets forward resolution and returns the computed node
    /// @dev Creates a subname under the parent node and sets the address record
    /// @param chainId The chain ID
    /// @param contractAddress The contract address to set in the address record
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    /// @return node The computed ENS node
    function setForwardResolution(uint256 chainId, address contractAddress, string memory fullName)
        internal
        returns (bool success, bytes32 node)
    {
        require(contractAddress != address(0), "Ens: contractAddress cannot be zero");
        (string memory label, string memory parentName) = CommonUtils.splitName(fullName);
        bytes32 parentNode = CommonUtils.namehash(parentName);
        bytes32 labelHash = keccak256(bytes(label));
        node = keccak256(abi.encodePacked(parentNode, labelHash));

        require(CommonUtils.isSenderOwner(chainId, parentNode), "Ens: sender is not the owner of parent node");
        require(createSubname(chainId, parentNode, labelHash), "Ens: subname creation failed");

        // Get resolver from node according to ENSIP-10, fall back to public resolver if none set
        address resolverAddr = CommonUtils.getResolverWithFallback(chainId, node);

        // Get the appropriate coin type for the chain
        uint256 coinType = CommonUtils.getCoinType(chainId);
        require(
            setAddr(resolverAddr, node, coinType, abi.encodePacked(contractAddress)),
            "Ens: setAddr, forward resolution failed"
        );
        return (true, node);
    }

    /// @notice Sets the primary (reverse) ENS name for an address
    /// @param chainId The chain ID
    /// @param addr The address whose primary name is being set
    /// @param node The forward resolution node for the ENS name
    /// @param name The full ENS name (e.g., "sub.domain.eth")
    /// @return success Whether the operation succeeded
    function setReverseResolution(uint256 chainId, address addr, bytes32 node, string memory name)
        internal
        returns (bool success)
    {
        // Check if primary name already exists and matches
        if (primaryNameMatches(chainId, addr, name)) {
            return true; // Already set correctly, skip
        }

        address reverseRegistrar = CommonUtils.getReverseRegistrar(chainId);
        require(reverseRegistrar != address(0), "Ens: reverseRegistrar not set for chain");

        // Get resolver from node according to ENSIP-10, fall back to public resolver if none set
        address resolverAddr = CommonUtils.getResolverWithFallback(chainId, node);
        require(resolverAddr != address(0), "Ens: resolver not set for node");

        try IL2ReverseRegistrar(reverseRegistrar).setNameForAddr(addr, name) {
            return true;
        } catch {
            return false;
        }
    }
}
