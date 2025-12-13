// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IReverseRegistrar
/// @notice Interface for ENS ReverseRegistrar contract
interface IReverseRegistrar {
    function setName(string memory name) external returns (bytes32 node);
    function setNameForAddr(address addr, address owner, address resolver, string calldata name) external;
    function node(address addr) external view returns (bytes32);
    function nameForAddr(address addr) external view returns (string memory);
}

/// @title IReverseRegistrar
/// @notice Interface for ENS ReverseRegistrar contract
interface IL2ReverseRegistrar {
    function setNameForAddr(address addr, string calldata name) external;
    function node(address addr) external view returns (bytes32);
    function nameForAddr(address addr) external view returns (string memory);
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

/// @title CommonUtils
/// @notice Common utility functions for ENS operations
library CommonUtils {
    /// @notice Ethereum Mainnet chain ID
    uint256 public constant ETHEREUM_MAINNET = 1;
    
    /// @notice Sepolia testnet chain ID
    uint256 public constant SEPOLIA = 11155111;
    
    /// @notice Optimism chain ID
    uint256 public constant OPTIMISM = 10;
    
    /// @notice Arbitrum One chain ID
    uint256 public constant ARBITRUM_ONE = 42161;
    
    /// @notice Base Mainnet chain ID
    uint256 public constant BASE_MAINNET = 8453;
    
    /// @notice Base Sepolia chain ID
    uint256 public constant BASE_SEPOLIA = 84532;
    /// @notice Splits a full ENS name into label and parent name
    /// @dev Finds the first dot and splits the name (e.g., "myname.eth" -> "myname", "eth")
    /// @param fullName The full ENS name (e.g., "myname.eth")
    /// @return label The label part (left of first dot)
    /// @return parentName The parent name part (right of first dot)
    function splitName(string memory fullName) internal pure returns (string memory label, string memory parentName) {
        bytes memory nameBytes = bytes(fullName);
        uint256 len = nameBytes.length;
        require(len > 0, "Ens: name cannot be empty");
        
        // Find the first dot
        uint256 dotIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (nameBytes[i] == 0x2e) { // '.' character
                dotIndex = i;
                break;
            }
        }
        
        require(dotIndex < len, "Ens: name must contain a dot");
        require(dotIndex > 0, "Ens: label cannot be empty");
        require(dotIndex < len - 1, "Ens: parent name cannot be empty");
        
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

    /// @notice Calculates the namehash (node) for a given ENS name
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

    /// @notice Gets the ENS Registry address
    /// @dev Returns the ENS Registry address which is same for all chains
    /// @return registry The address of the ENS Registry contract
    function getRegistry(uint256 chainId) internal pure returns (address registry) {
        if (chainId == ETHEREUM_MAINNET) {
            return 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
        } else if (chainId == SEPOLIA) {
            return 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
        } else if (chainId == OPTIMISM) {
            return 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
        } else if (chainId == ARBITRUM_ONE) {
            return 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
        } else if (chainId == BASE_MAINNET) {
            return 0xB94704422c2a1E396835A571837Aa5AE53285a95;
        } else if (chainId == BASE_SEPOLIA) {
            return 0x1493b2567056c2181630115660963E13A8E32735;
        } else {
            return address(0);
        }
    }

    /// @notice Gets the Public Resolver address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return resolver The address of the Public Resolver contract for the given chain
    function getPublicResolver(uint256 chainId) internal pure returns (address resolver) {
        if (chainId == ETHEREUM_MAINNET) {
            return 0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63;
        } else if (chainId == SEPOLIA) {
            return 0xE99638b40E4Fff0129D56f03b55b6bbC4BBE49b5;
        } else if (chainId == OPTIMISM) {
            return address(0);
        } else if (chainId == ARBITRUM_ONE) {
            return address(0);
        } else if (chainId == BASE_MAINNET) {
            return 0xC6d566A56A1aFf6508b41f6c90ff131615583BCD;
        } else if (chainId == BASE_SEPOLIA) {
            return 0xC6d566A56A1aFf6508b41f6c90ff131615583BCD;
        } else {
            return address(0);
        }
    }

    /// @notice Gets the NameWrapper address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return nameWrapper The address of the NameWrapper contract for the given chain
    function getNameWrapper(uint256 chainId) internal pure returns (address nameWrapper) {
        if (chainId == ETHEREUM_MAINNET) {
            return 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401;
        } else if (chainId == SEPOLIA) {
            return 0x0635513f179D50A207757E05759CbD106d7dFcE8;
        } else if (chainId == OPTIMISM) {
            return address(0);
        } else if (chainId == ARBITRUM_ONE) {
            return address(0);
        } else if (chainId == BASE_MAINNET) {
            return address(0);
        } else {
            return address(0);
        }
    }

    /// @notice Gets the ReverseRegistrar address for a given chain ID
    /// @dev Uses branching to return the appropriate address based on chainId
    /// @param chainId The chain ID
    /// @return reverseRegistrar The address of the ReverseRegistrar contract for the given chain
    function getReverseRegistrar(uint256 chainId) internal pure returns (address reverseRegistrar) {
        if (chainId == ETHEREUM_MAINNET) {
            return 0xa58E81fe9b61B5c3fE2AFD33CF304c454AbFc7Cb;
        } else if (chainId == SEPOLIA) {
            return 0xA0a1AbcDAe1a2a4A2EF8e9113Ff0e02DD81DC0C6;
        } else if (chainId == OPTIMISM) {
            return 0x0000000000D8e504002cC26E3Ec46D81971C1664;
        } else if (chainId == ARBITRUM_ONE) {
            return 0x0000000000D8e504002cC26E3Ec46D81971C1664;
        } else if (chainId == BASE_MAINNET) {
            return 0x0000000000D8e504002cC26E3Ec46D81971C1664;
        } else if (chainId == BASE_SEPOLIA) {
            return 0x00000BeEF055f7934784D6d81b6BC86665630dbA;
        } else {
            return address(0);
        }
    }

    /// @notice Gets the resolver address for a given ENS node
    /// @param chainId The chain ID
    /// @param node The ENS node
    /// @return resolver The resolver address for the node
    function getResolver(uint256 chainId, bytes32 node) internal view returns (address resolver) {
        address registry = getRegistry(chainId);
        require(registry != address(0), "Ens: unsupported chainId");
        return IENSRegistry(registry).resolver(node);
    }

    /// @notice Gets the resolver address for a given ENS node with fallback to public resolver
    /// @dev Gets resolver from node according to ENSIP-10, falls back to public resolver if none set
    /// @param chainId The chain ID
    /// @param node The ENS node
    /// @return resolver The resolver address for the node (or public resolver if none set)
    function getResolverWithFallback(uint256 chainId, bytes32 node) internal view returns (address resolver) {
        address registry = getRegistry(chainId);
        resolver = IENSRegistry(registry).resolver(node);
        if (resolver == address(0)) {
            resolver = getPublicResolver(chainId);
        }
        return resolver;
    }

    /// @notice Checks if an ENS name is wrapped
    /// @param chainId The chain ID
    /// @param node The ENS node
    /// @return wrapped Whether the name is wrapped
    function isWrapped(uint256 chainId, bytes32 node) internal view returns (bool wrapped) {
        address nameWrapper = getNameWrapper(chainId);
        if (nameWrapper == address(0)) {
            return false;
        }
        try INameWrapper(nameWrapper).isWrapped(node) returns (bool isWrappedResult) {
            return isWrappedResult;
        } catch {
            return false;
        }
    }

    /// @notice Verifies if msg.sender is owner of the given node
    /// @param chainId The chain ID
    /// @param node The ENS node
    /// @return isOwner Whether msg.sender is the owner
    function isSenderOwner(uint256 chainId, bytes32 node) internal view returns (bool isOwner) {
        address registry = getRegistry(chainId);
        address nameWrapper = getNameWrapper(chainId);
        
        require(registry != address(0), "Ens: unsupported chainId");

        if (isWrapped(chainId, node)) {
            return INameWrapper(nameWrapper).ownerOf(uint256(node)) == msg.sender;
        } else {
            return IENSRegistry(registry).owner(node) == msg.sender;
        }
    }

    /// @notice Gets the coin type for a given chain ID
    /// @param chainId The chain ID
    /// @return coinType The coin type for the chain (60 for ETH on most chains)
    function getCoinType(uint256 chainId) internal pure returns (uint256 coinType) {
        if (chainId == ETHEREUM_MAINNET) {
            return 60;
        } else if (chainId == SEPOLIA) {
            return 60;
        } else if (chainId == OPTIMISM) {
            return 2147483658;
        } else if (chainId == ARBITRUM_ONE) {
            return 2147525809;
        } else if (chainId == BASE_MAINNET) {
            return 2147492101;
        } else if (chainId == BASE_SEPOLIA) {
            return 2147568180;
        } else {
            return 60;
        }
    }
}

