// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IReverseRegistrar
/// @notice Interface for ENS ReverseRegistrar contract
interface IReverseRegistrar {
    function setName(string memory name) external returns (bytes32 node);
    function setNameForAddr(address addr, address owner, address resolver, string calldata name) external;
    function node(address addr) external view returns (bytes32);
}

/// @title IENSRegistry
/// @notice Interface for ENS Registry contract
interface IENSRegistry {
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setOwner(bytes32 node, address owner) external;
}

/// @title IPublicResolver
/// @notice Interface for ENS Public Resolver contract
interface IPublicResolver {
    function setAddr(bytes32 node, uint256 coinType, bytes calldata a) external;
    function setAddr(bytes32 node, address a) external;
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
    function addr(bytes32 node) external view returns (address payable);
    function setName(bytes32 node, string calldata newName) external;
    function name(bytes32 node) external view returns (string memory);
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

/// @title INameWrapper
/// @notice Interface for ENS NameWrapper contract
interface INameWrapper {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isWrapped(bytes32 node) external view returns (bool);
    function setSubnodeRecord(bytes32 node, string calldata label, address owner, address resolver, uint64 ttl, uint32 fuses, uint64 expiry) external;
}

/// @title NameSetterUtils
/// @notice Utility library for ENS operations
library NameSetterUtils {
    /// @notice Internal: Splits a full ENS name into label and parent name
    /// @dev Finds the first dot and splits the name (e.g., "myname.eth" -> "myname", "eth")
    /// @param fullName The full ENS name (e.g., "myname.eth")
    /// @return label The label part (left of first dot)
    /// @return parentName The parent name part (right of first dot)
    function splitName(string memory fullName) internal pure returns (string memory label, string memory parentName) {
        bytes memory nameBytes = bytes(fullName);
        uint256 len = nameBytes.length;
        require(len > 0, "NameSetter: name cannot be empty");
        
        // Find the first dot
        uint256 dotIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (nameBytes[i] == 0x2e) { // '.' character
                dotIndex = i;
                break;
            }
        }
        
        require(dotIndex < len, "NameSetter: name must contain a dot");
        require(dotIndex > 0, "NameSetter: label cannot be empty");
        require(dotIndex < len - 1, "NameSetter: parent name cannot be empty");
        
        // Extract label (left part)
        bytes memory labelBytes = new bytes(dotIndex);
        for (uint256 i = 0; i < dotIndex; i++) {
            labelBytes[i] = nameBytes[i];
        }
        label = string(labelBytes);
        
        // Extract parent name (right part, excluding the dot)
        bytes memory parentBytes = new bytes(len - dotIndex - 1);
        for (uint256 i = 0; i < parentBytes.length; i++) {
            parentBytes[i] = nameBytes[dotIndex + 1 + i];
        }
        parentName = string(parentBytes);
    }

    /// @notice Internal: Calculates the namehash (node) for a given ENS name
    /// @dev Recursively calculates the namehash following ENS namehash algorithm
    /// @param name The ENS name (e.g., "eth" or "sub.eth")
    /// @return node The calculated node hash
    function namehash(string memory name) internal pure returns (bytes32 node) {
        node = bytes32(0);
        if (bytes(name).length == 0) {
            return node;
        }
        
        // Split the name by dots and process from right to left
        bytes memory nameBytes = bytes(name);
        uint256 len = nameBytes.length;
        uint256 labelStart = len;
        
        // Process labels from right to left
        for (uint256 i = len; i > 0; i--) {
            if (nameBytes[i - 1] == 0x2e) { // '.' character
                if (labelStart > i) {
                    bytes memory label = new bytes(labelStart - i);
                    for (uint256 j = 0; j < label.length; j++) {
                        label[j] = nameBytes[i + j];
                    }
                    node = keccak256(abi.encodePacked(node, keccak256(label)));
                }
                labelStart = i - 1;
            }
        }
        
        // Process the last (leftmost) label
        if (labelStart > 0) {
            bytes memory label = new bytes(labelStart);
            for (uint256 j = 0; j < labelStart; j++) {
                label[j] = nameBytes[j];
            }
            node = keccak256(abi.encodePacked(node, keccak256(label)));
        }
        
        return node;
    }

    /// @notice Internal: Creates ENS subname under given parent
    /// @dev Uses msg.sender as the owner of the created subname
    function _createSubname(uint256 chainId, bytes32 parentNode, string memory label, bytes32 labelHash) internal returns (bool) {
        address registry = _getRegistry();
        address nameWrapper = _getNameWrapper(chainId);
        address resolver = _getResolver(chainId, parentNode);
        
        require(registry != address(0), "NameSetter: unsupported chainId");
        require(resolver != address(0), "NameSetter: resolver not set for parent node");

        // Compute the subname node
        bytes32 subnameNode = keccak256(abi.encodePacked(parentNode, labelHash));
        
        // Check if subname already exists and get the owner
        address existingOwner = address(0);
        bool subnameExists = false;
        
        // Check if subname is wrapped first (wrapped names are owned via NameWrapper)
        bool subnameIsWrapped = _checkWrapped(chainId, subnameNode);
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
        require(!subnameExists, "NameSetter: subname already exists and is owned by another address");

        // Create the subname if it doesn't exist
        if (_checkWrapped(chainId, parentNode)) {
            INameWrapper(nameWrapper).setSubnodeRecord(parentNode, label, msg.sender, resolver, 0, 0, 0);
        } else {
            IENSRegistry(registry).setSubnodeRecord(parentNode, labelHash, msg.sender, resolver, 0);
        }
        return true;
    }

    /// @notice Internal: Checks if address record already exists and matches the target address
    function _addrMatches(uint256 chainId, bytes32 node, uint256 coinType, bytes memory targetAddrBytes) internal view returns (bool) {
        address resolverAddr = _getResolver(chainId, node);
        if (resolverAddr == address(0)) {
            return false;
        }
        
        try IPublicResolver(resolverAddr).addr(node, coinType) returns (bytes memory existingAddrBytes) {
            return keccak256(existingAddrBytes) == keccak256(targetAddrBytes);
        } catch {
            return false;
        }
    }

    /// @notice Internal: Sets address record, forward resolution
    function _setAddr(uint256 chainId, bytes32 node, uint256 coinType, bytes memory addrBytes) internal returns (bool) {
        // Check if address record already exists and matches
        if (_addrMatches(chainId, node, coinType, addrBytes)) {
            return true; // Already set correctly, skip
        }
        
        address resolverAddr = _getResolver(chainId, node);
        require(resolverAddr != address(0), "NameSetter: resolver not set for node");
        
        try IPublicResolver(resolverAddr).setAddr(node, coinType, addrBytes) {
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Internal: Checks if reverse/primary name already exists and matches the target name
    function _primaryNameMatches(uint256 chainId, address addr, bytes32 node, string memory targetName) internal view returns (bool) {
        // Get the reverse node for the address
        address reverseRegistrar = _getReverseRegistrar(chainId);
        if (reverseRegistrar == address(0)) {
            return false;
        }
        
        try IReverseRegistrar(reverseRegistrar).node(addr) returns (bytes32 reverseNode) {
            if (reverseNode == bytes32(0)) {
                return false; // No reverse node set
            }
            
            // Get the resolver for the reverse node
            address registry = _getRegistry();
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

    /// @notice Internal: Sets the primary (reverse) ENS name for an address
    /// @param chainId The chain ID to determine which ReverseRegistrar to use
    /// @param addr The address whose primary name is being set (typically the deployed contract)
    /// @param node The forward resolution node for the ENS name
    /// @param name The full ENS name (e.g., "sub.domain.eth")
    /// @return success Whether the operation succeeded (does not revert on ReverseRegistrar failure)
    function _setPrimaryName(
        uint256 chainId,
        address addr,
        bytes32 node,
        string memory name
    ) internal returns (bool success) {
        // Check if primary name already exists and matches
        if (_primaryNameMatches(chainId, addr, node, name)) {
            return true; // Already set correctly, skip
        }
        
        address reverseRegistrar = _getReverseRegistrar(chainId);
        require(reverseRegistrar != address(0), "NameSetter: reverseRegistrar not set for chainId");

        address resolverAddr = _getResolver(chainId, node);
        require(resolverAddr != address(0), "NameSetter: resolver not set for node");

        try IReverseRegistrar(reverseRegistrar).setNameForAddr(addr, msg.sender, resolverAddr, name) {
            return true;
        } catch {
            return false;
        }
    }

    /// @notice Internal helper that sets forward resolution and returns the computed node
    /// @dev Creates a subname under the parent node and sets the address record
    /// @param chainId The chain ID to determine which ENS contracts to use
    /// @param contractAddress The contract address to set in the address record
    /// @param fullName The full ENS name (e.g., "myawesomeapp.mydomain.eth")
    /// @return success Whether the operation succeeded
    /// @return node The computed ENS node
    function _setForwardResolutionInternal(
        uint256 chainId,
        address contractAddress,
        string memory fullName
    ) internal returns (bool success, bytes32 node) {
        (string memory label, string memory parentName) = splitName(fullName);
        bytes32 parentNode = namehash(parentName);
        bytes32 labelHash = keccak256(bytes(label));
        node = keccak256(abi.encodePacked(parentNode, labelHash));

        require(_isSenderOwner(chainId, parentNode), "NameSetter: sender is not the owner of parent node");
        require(_createSubname(chainId, parentNode, label, labelHash), "NameSetter: subname creation failed");

        require(_setAddr(chainId, node, 60, abi.encodePacked(contractAddress)), "NameSetter: setAddr, forward resolution failed");
        return (true, node);
    }

    /// @notice Internal: Returns the Resolver address for given ENS node
    function _getResolver(uint256 chainId, bytes32 node) internal view returns (address) {
        address registry = _getRegistry();
        require(registry != address(0), "NameSetter: unsupported chainId");
        return IENSRegistry(registry).resolver(node);
    }

    /// @notice Internal: Returns whether the ENS name is wrapped
    function _checkWrapped(uint256 chainId, bytes32 node) internal view returns (bool) {
        address nameWrapper = _getNameWrapper(chainId);
        if (nameWrapper == address(0)) {
            return false;
        }
        try INameWrapper(nameWrapper).isWrapped(node) returns (bool wrapped) {
            return wrapped;
        } catch {
            return false;
        }
    }

    /// @notice Internal: Verifies if msg.sender is owner of the given node
    function _isSenderOwner(uint256 chainId, bytes32 node) internal view returns (bool) {
        address registry = _getRegistry();
        address nameWrapper = _getNameWrapper(chainId);
        
        require(registry != address(0), "NameSetter: unsupported chainId");

        if (_checkWrapped(chainId, node)) {
            return INameWrapper(nameWrapper).ownerOf(uint256(node)) == msg.sender;
        } else {
            return IENSRegistry(registry).owner(node) == msg.sender;
        }
    }

    /// @notice Gets the reverseRegistrar address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return reverseRegistrar The address of the ReverseRegistrar contract for the given chain
    function _getReverseRegistrar(uint256 chainId) internal pure returns (address reverseRegistrar) {
        if (chainId == 1) {
            // Ethereum Mainnet
            return 0xa58E81fe9b61B5c3fE2AFD33CF304c454AbFc7Cb;
        } else if (chainId == 11155111) {
            // Sepolia
            return 0xA0a1AbcDAe1a2a4A2EF8e9113Ff0e02DD81DC0C6;
        } else if (chainId == 10) {
            // Optimism
            return 0x0000000000D8e504002cC26E3Ec46D81971C1664;
        } else if (chainId == 42161) {
            // Arbitrum One
            return 0x0000000000D8e504002cC26E3Ec46D81971C1664;
        } else if (chainId == 8453) {
            // Base
            return 0x0000000000D8e504002cC26E3Ec46D81971C1664;
        } else {
            return address(0);
        }
    }

    /// @notice Gets the ENS Registry address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return registry The address of the ENS Registry contract for the given chain
    function getRegistry(uint256 chainId) internal pure returns (address registry) {
        return _getRegistry();
    }

    /// @notice Gets the Public Resolver address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return resolver The address of the Public Resolver contract for the given chain
    function getPublicResolver(uint256 chainId) internal pure returns (address resolver) {
        return _getPublicResolver(chainId);
    }

    /// @notice Gets the NameWrapper address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return nameWrapper The address of the NameWrapper contract for the given chain
    function getNameWrapper(uint256 chainId) internal pure returns (address nameWrapper) {
        return _getNameWrapper(chainId);
    }

    /// @notice Gets the ReverseRegistrar address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return reverseRegistrar The address of the ReverseRegistrar contract for the given chain
    function getReverseRegistrar(uint256 chainId) internal pure returns (address reverseRegistrar) {
        return _getReverseRegistrar(chainId);
    }

    /// @notice Gets the ENS Registry address
    /// @dev Returns the ENS Registry address which is same for all chains
    /// @return registry The address of the ENS Registry contract
    function _getRegistry() private pure returns (address registry) {
        return 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    }

    /// @notice Gets the Public Resolver address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return resolver The address of the Public Resolver contract for the given chain
    function _getPublicResolver(uint256 chainId) private pure returns (address resolver) {
        if (chainId == 1) {
            // Ethereum Mainnet
            return 0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63;
        } else if (chainId == 11155111) {
            // Sepolia
            return 0xE99638b40E4Fff0129D56f03b55b6bbC4BBE49b5;
        } else if (chainId == 10) {
            // Optimism
            return address(0);
        } else if (chainId == 42161) {
            // Arbitrum One
            return address(0);
        } else if (chainId == 8453) {
            // Base
            return 0xC6d566A56A1aFf6508b41f6c90ff131615583BCD;
        } else {
            return address(0);
        }
    }

    /// @notice Gets the NameWrapper address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return nameWrapper The address of the NameWrapper contract for the given chain
    function _getNameWrapper(uint256 chainId) private pure returns (address nameWrapper) {
        if (chainId == 1) {
            // Ethereum Mainnet
            return 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401;
        } else if (chainId == 11155111) {
            // Sepolia
            return 0x0635513f179D50A207757E05759CbD106d7dFcE8;
        } else if (chainId == 10) {
            // Optimism
            return address(0);
        } else if (chainId == 42161) {
            // Arbitrum One
            return address(0);
        } else if (chainId == 8453) {
            // Base
            return address(0);
        } else {
            return address(0);
        }
    }
}

