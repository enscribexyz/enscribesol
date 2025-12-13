// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Ens} from "../src/Ens.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

/// @title EnsIntegrationHarness
/// @notice Simple harness contract that exposes the Ens library for integration tests
contract EnsIntegrationHarness {
    function setContractName(
        uint256 chainId,
        address contractAddress,
        string calldata fullName
    ) external {
        Ens.setName(chainId, contractAddress, fullName);
    }
}

/// @title EnsIntegrationTest
/// @notice Integration test that deploys a HelloWorld contract and registers a primary ENS name for it
contract EnsIntegrationTest is Test {
    EnsIntegrationHarness public harness;
    HelloWorld public helloWorld;

    // Adjust this if your local Anvil/ENS setup uses a different chainId mapping
    uint256 internal constant CHAIN_ID = 31337;

    function setUp() public {
        harness = new EnsIntegrationHarness();
        helloWorld = new HelloWorld("Hello, world!", 0);
    }

    /// @notice Deploys HelloWorld and registers a primary name using Ens.setName
    /// @dev This assumes your local Anvil node has ENS contracts deployed at the canonical
    ///      addresses expected by CommonUtils, and that msg.sender (this test contract)
    ///      is the owner of the parent node for `fullName` on that ENS registry.
    function test_SetPrimaryNameForHelloWorld() public {
        // Full ENS name to register as the primary / reverse name for the deployed contract
        string memory fullName = "helloworld.eth";

        // Call into the harness, which in turn uses the Ens library
        // This will:
        // 1. Split the name into label + parent
        // 2. Verify msg.sender owns the parent node
        // 3. Create the subname and set forward resolution (addr record)
        // 4. Set the primary (reverse) name using ReverseRegistrar.setNameForAddr
        harness.setContractName(CHAIN_ID, address(helloWorld), fullName);

        // If we reach here without reverting, forward + reverse setup has succeeded
        // against your local ENS deployment.
        assertTrue(true, "setName completed without revert");
    }
}


