// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommonUtils.sol";

/// @title L1NameSetter
/// @notice Library for L1 ENS operations (Mainnet, Sepolia, Optimism, Arbitrum)
/// @dev Handles subname creation, forward resolution, and reverse resolution for L1 chains
library L1NameSetter {
    /// @notice Creates ENS subname under given parent
    /// @dev Uses msg.sender as the owner of the created subname
    /// @param chainId The chain ID
    /// @param parentNode The parent node
    /// @param label The label for the subname
    /// @param labelHash The hash of the label
    /// @return success Whether the operation succeeded
    function createSubname(uint256 chainId, bytes32 parentNode, string memory label, bytes32 labelHash) internal returns (bool success) {
        address registry = CommonUtils.getRegistry(chainId);
        address nameWrapper = CommonUtils.getNameWrapper(chainId);
        
        require(registry != address(0), "Ens: unsupported chainId");
        
        // Get resolver from parent node according to ENSIP-10, fall back to public resolver if none set
        address resolver = IENSRegistry(registry).resolver(parentNode);
        if (resolver == address(0)) {
            resolver = CommonUtils.getPublicResolver(chainId);
        }
        require(resolver != address(0), "Ens: resolver not set for parent node");

        // Compute the subname node
        bytes32 subnameNode = keccak256(abi.encodePacked(parentNode, labelHash));
        
        // Check if subname already exists and get the owner
        address existingOwner = address(0);
        bool subnameExists = false;
        
        // Check if subname is wrapped first (wrapped names are owned via NameWrapper)
        bool subnameIsWrapped = CommonUtils.isWrapped(chainId, subnameNode);
        if (subnameIsWrapped && nameWrapper != address(0)) {
            try INameWrapper(nameWrapper).ownerOf(uint256(subnameNode)) returns (address owner) {
                existingOwner = owner;
                subnameExists = (owner != address(0));
            } catch {
                // If ownerOf fails, subname doesn't exist
            }
        } else {
            // For unwrapped names, check registry
            existingOwner = IENSRegistry(registry).owner(subnameNode);
            subnameExists = (existingOwner != address(0));
        }
        
        // If subname exists and we own it, skip creation
        if (subnameExists && existingOwner == msg.sender) {
            return true;
        }
        
        // If subname exists but we don't own it, revert
        require(!subnameExists, "Ens: subname already exists and is owned by another address");

        // Create the subname if it doesn't exist
        if (CommonUtils.isWrapped(chainId, parentNode)) {
            INameWrapper(nameWrapper).setSubnodeRecord(parentNode, label, msg.sender, resolver, 0, 0, 0);
        } else {
            IENSRegistry(registry).setSubnodeRecord(parentNode, labelHash, msg.sender, resolver, 0);
        }
        return true;
    }

    /// @notice Checks if address record already exists and matches the target address
    /// @param resolverAddr The resolver address to use
    /// @param node The ENS node
    /// @param coinType The coin type (60 for ETH)
    /// @param targetAddrBytes The target address as bytes
    /// @return matches Whether the existing address matches the target
    function addrMatches(address resolverAddr, bytes32 node, uint256 coinType, bytes memory targetAddrBytes) internal view returns (bool matches) {
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
    function setAddr(address resolverAddr, bytes32 node, uint256 coinType, bytes memory addrBytes) internal returns (bool success) {
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
    function primaryNameMatches(uint256 chainId, address addr, string memory targetName) internal view returns (bool matches) {
        // Get the reverse node for the address
        address reverseRegistrar = CommonUtils.getReverseRegistrar(chainId);
        if (reverseRegistrar == address(0)) {
            return false;
        }
        
        try IReverseRegistrar(reverseRegistrar).node(addr) returns (bytes32 reverseNode) {
            if (reverseNode == bytes32(0)) {
                return false; // No reverse node set
            }
            
            // Get the resolver for the reverse node
            address registry = CommonUtils.getRegistry(chainId);
            if (registry == address(0)) {
                return false;
            }
            
            address resolverAddr = IENSRegistry(registry).resolver(reverseNode);
            if (resolverAddr == address(0)) {
                return false;
            }
            
            // Check if the name in the resolver for the reverse node matches
            try IPublicResolver(resolverAddr).name(reverseNode) returns (string memory existingName) {
                return keccak256(bytes(existingName)) == keccak256(bytes(targetName));
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }

    /// @notice Sets the primary (reverse) ENS name for an address
    /// @param chainId The chain ID
    /// @param addr The address whose primary name is being set
    /// @param node The forward resolution node for the ENS name
    /// @param name The full ENS name (e.g., "sub.domain.eth")
    /// @return success Whether the operation succeeded
    function setReverseResolution(
        uint256 chainId,
        address addr,
        bytes32 node,
        string memory name
    ) internal returns (bool success) {
        // Check if primary name already exists and matches
        if (primaryNameMatches(chainId, addr, name)) {
            return true; // Already set correctly, skip
        }
        
        address reverseRegistrar = CommonUtils.getReverseRegistrar(chainId);
        require(reverseRegistrar != address(0), "Ens: reverseRegistrar not set for chainId");

        // Get resolver from node according to ENSIP-10, fall back to public resolver if none set
        address resolverAddr = CommonUtils.getResolverWithFallback(chainId, node);
        require(resolverAddr != address(0), "Ens: resolver not set for node");

        try IReverseRegistrar(reverseRegistrar).setNameForAddr(addr, msg.sender, resolverAddr, name) {
            return true;
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
    function setForwardResolution(
        uint256 chainId,
        address contractAddress,
        string memory fullName
    ) internal returns (bool success, bytes32 node) {
        require(contractAddress != address(0), "Ens: contractAddress cannot be zero");
        (string memory label, string memory parentName) = CommonUtils.splitName(fullName);
        bytes32 parentNode = CommonUtils.namehash(parentName);
        bytes32 labelHash = keccak256(bytes(label));
        node = keccak256(abi.encodePacked(parentNode, labelHash));

        require(CommonUtils.isSenderOwner(chainId, parentNode), "Ens: sender is not the owner of parent node");
        require(createSubname(chainId, parentNode, label, labelHash), "Ens: subname creation failed");

        // Get resolver from node according to ENSIP-10, fall back to public resolver if none set
        address resolverAddr = CommonUtils.getResolverWithFallback(chainId, node);

        // Get the appropriate coin type for the chain
        uint256 coinType = CommonUtils.getCoinType(chainId);
        require(setAddr(resolverAddr, node, coinType, abi.encodePacked(contractAddress)), "Ens: setAddr, forward resolution failed");
        return (true, node);
    }

    /// @notice Sets name for L1 chains (Mainnet, Sepolia, Optimism, Arbitrum)
    /// @dev Creates a subname, sets forward resolution, and sets reverse/primary name
    /// @param chainId The chain ID
    /// @param contractAddress The contract address to name
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    function setName(
        uint256 chainId,
        address contractAddress,
        string memory fullName
    ) internal returns (bool success) {
        require(contractAddress != address(0), "Ens: contractAddress cannot be zero");
        (bool forwardSuccess, bytes32 node) = setForwardResolution(chainId, contractAddress, fullName);
        require(forwardSuccess, "Ens: forward resolution failed");
        
        // After forward resolution succeeds, set reverse/primary name
        require(setReverseResolution(chainId, contractAddress, node, fullName), "Ens: setReverseResolution failed");
        
        return true;
    }
}

