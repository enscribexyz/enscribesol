// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Ens} from "../src/Ens.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

/// @title HelloWorldDeployScript
/// @notice Forge script to deploy HelloWorld and set its ENS primary name
contract HelloWorldSetNameForExisting is Script {
    function run() public {
        vm.startBroadcast();

        // Register primary name for already deployed contract using Ens
        // Ens.setName(block.chainid, 0x7f9E2Cdd7cFC02622eD63D498D869bEA90AE87D1, "enscribesolfwdres11.abhi.eth");
        Ens.setName(block.chainid, 0xAC2D499D279aDF958E3F1c1E75886B3f59E141ab, "enscribesolbasetest1.abhi.basetest.eth");

        vm.stopBroadcast();
    }
}


