// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {NameSetter} from "../src/NameSetter.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

/// @title HelloWorldDeployScript
/// @notice Forge script to deploy HelloWorld and set its ENS primary name via NameSetter
contract HelloWorldSetNameForExisting is Script {
    function run() public {
        vm.startBroadcast();

        // Register primary name for already deployed contract using NameSetter
        NameSetter.setName(block.chainid, 0xb92339f9E343a171223AA9F4ABd1f32269631F95, "enscribesol2.abhi.eth");

        vm.stopBroadcast();
    }
}


