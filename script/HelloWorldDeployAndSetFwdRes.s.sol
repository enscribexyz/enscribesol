// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Ens} from "../src/Ens.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

/// @title HelloWorldDeployAndSetFwdResScript
/// @notice Forge script to deploy HelloWorld and set its ENS primary name via Ens
contract HelloWorldDeployAndSetFwdResScript is Script {
    function run() public {
        vm.startBroadcast();

        // 1. Deploy the HelloWorld contract on-chain
        HelloWorld hello = new HelloWorld("hi forge!", 0);

        // 2. Register primary name for the deployed contract using Ens
        // Ens.setForwardResolution(block.chainid, address(hello), "enscribesolfwdres11.abhi.eth");
        Ens.setForwardResolution(block.chainid, address(hello), "enscribesolbasetest3.abhi.basetest.eth");

        vm.stopBroadcast();
    }
}