`enscribesol` is a Solidity library that provides a simple interface for assigning ENS names to contracts. It handles the complete ENS naming flow:

- Subname creation under a parent domain
- Forward resolution (name → address)
- Reverse resolution (address → name)

## Installation

The library can be installed as a dependency in your Foundry project:

```bash
forge install enscribexyz/enscribesol
```

Then add this to your `remappings.txt`:

```toml
enscribesol/=lib/enscribesol/src/
```

## Quick Start

The simplest way to use the library is to import it in your foundry script and call the `setName` function:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {NameSetter} from "enscribesol/Ens.sol";

contract MyContractScript is Script {
    function run() public {
        vm.startBroadcast();

        counter = new Counter();
        Ens.setName(block.chainid, address(counter), "mycontract.mydomain.eth");

        vm.stopBroadcast();
    }
}
```

## Public API

### Core Functions

#### `Ens.setName()`

Sets both forward and reverse resolution for a contract address. This is the main function you'll use in most cases.

**Function Signature:**
```solidity
function setName(
    uint256 chainId,
    address contractAddress,
    string memory fullName
) internal returns (bool success)
```

**Parameters:**
- `chainId`: The chain ID where the contract is deployed (e.g., `1` for Ethereum Mainnet, `8453` for Base Mainnet)
- `contractAddress`: The address of the contract to name (must not be zero address)
- `fullName`: The full ENS name to assign (e.g., `"mycontract.mydomain.eth"`)

**Returns:**
- `success`: `true` if the operation succeeded, `false` otherwise

**What it does:**
1. Creates a subname under the parent domain
2. Sets forward resolution (name → address mapping)
3. Sets reverse resolution (address → name mapping)

**Example:**
```solidity
import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {NameSetter} from "enscribesol/Ens.sol";

contract MyContractScript is Script {
    function run() public {
        vm.startBroadcast();

        counter = new Counter();
        Ens.setName(block.chainid, address(counter), "mycontract.mydomain.eth");

        vm.stopBroadcast();
    }
}
```

**Requirements:**
- The caller (`msg.sender`) must own the parent ENS node (e.g., `mydomain.eth`)
- The `contractAddress` must not be the zero address
- The `fullName` must be a valid ENS name format (contains at least one dot)

---

#### `Ens.setForwardResolution()`

Sets only forward resolution (name → address) without setting reverse resolution. Useful when you only need forward lookup.

**Function Signature:**
```solidity
function setForwardResolution(
    uint256 chainId,
    address contractAddress,
    string memory fullName
) internal returns (bool success)
```

**Parameters:**
- `chainId`: The chain ID where the contract is deployed
- `contractAddress`: The address of the contract to name
- `fullName`: The full ENS name to assign

**Returns:**
- `success`: `true` if the operation succeeded, `false` otherwise

**Example:**
```solidity
import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {NameSetter} from "enscribesol/Ens.sol";

contract MyContractScript is Script {
    function run() public {
        vm.startBroadcast();

        counter = new Counter();
        Ens.setForwardResolution(block.chainid, address(counter), "mycontract.mydomain.eth");

        vm.stopBroadcast();
    }
}
```