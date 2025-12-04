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
    function setName(bytes32 node, string calldata newName) external;
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
    function _createSubname(uint256 chainId, bytes32 parentNode, string memory label, bytes32 labelHash, address owner) internal returns (bool) {
        address registry = _getRegistry();
        address nameWrapper = _getNameWrapper(chainId);
        address resolver = _getResolver(chainId, parentNode);
        
        require(registry != address(0), "NameSetter: unsupported chainId");
        require(resolver != address(0), "NameSetter: resolver not set for parent node");

        if (_checkWrapped(chainId, parentNode)) {
            INameWrapper(nameWrapper).setSubnodeRecord(parentNode, label, owner, resolver, 0, 0, 0);
        } else {
            IENSRegistry(registry).setSubnodeRecord(parentNode, labelHash, owner, resolver, 0);
        }
        return true;
    }

    /// @notice Internal: Sets address record, forward resolution
    function _setAddr(uint256 chainId, bytes32 node, uint256 coinType, bytes memory addrBytes) internal returns (bool) {
        address resolverAddr = _getResolver(chainId, node);
        require(resolverAddr != address(0), "NameSetter: resolver not set for node");
        
        try IPublicResolver(resolverAddr).setAddr(node, coinType, addrBytes) {
            return true;
        } catch {
            return false;
        }
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

    /// @notice Internal: Verifies if the address is owner of the given node
    function _isSenderOwner(uint256 chainId, bytes32 node, address owner) internal view returns (bool) {
        address registry = _getRegistry();
        address nameWrapper = _getNameWrapper(chainId);
        
        require(registry != address(0), "NameSetter: unsupported chainId");

        if (_checkWrapped(chainId, node)) {
            return INameWrapper(nameWrapper).ownerOf(uint256(node)) == owner;
        } else {
            return IENSRegistry(registry).owner(node) == owner;
        }
    }

    /// @notice Gets the reverseRegistrar address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return reverseRegistrar The address of the ReverseRegistrar contract for the given chain
    function _getReverseRegistrar(uint256 chainId) internal pure returns (address reverseRegistrar) {
        if (chainId == 1) {
            // Ethereum Mainnet
            return 0x084b1c3C81545d370f3634392De611CaaBFf8148;
        } else if (chainId == 11155111) {
            // Sepolia
            return 0x8e9Bd30D15420bAe4B7EC0aC014B7ECeE864373C;
        } else if (chainId == 10) {
            // Optimism
            return 0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c;
        } else if (chainId == 42161) {
            // Arbitrum One
            return 0x4ef8F50bedd8a073d7f5e4Cf6ce1b3d9B8d1c5a1;
        } else if (chainId == 8453) {
            // Base
            return 0x4ef8F50bedd8a073d7f5e4Cf6ce1b3d9B8d1c5a1;
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
            return 0x0635513F179D50AFB97D942A5D3c54C2F838B8f4;
        } else if (chainId == 10) {
            // Optimism
            return 0x888811F1B21176E15FB60DF500eA85B490Dd2836;
        } else if (chainId == 42161) {
            // Arbitrum One
            return 0x888811F1B21176E15FB60DF500eA85B490Dd2836;
        } else if (chainId == 8453) {
            // Base
            return 0x888811F1B21176E15FB60DF500eA85B490Dd2836;
        } else {
            return address(0);
        }
    }
}

