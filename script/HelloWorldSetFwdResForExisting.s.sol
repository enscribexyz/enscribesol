// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {NameSetter} from "../src/NameSetter.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

/// @title HelloWorldSetFwdResForExistingScript
/// @notice Forge script to deploy HelloWorld and set its ENS primary name via NameSetter
contract HelloWorldSetFwdResForExistingScript is Script {
    function run() public {
        vm.startBroadcast();

        // Set fwd res for an existing contract address
        NameSetter.setForwardResolution(block.chainid, 0xA1c2e6ce0573Cf1b8B0E17207770804935bcC6B6, "enscribesolfwdres9.abhi.eth");

        vm.stopBroadcast();
    }
}


