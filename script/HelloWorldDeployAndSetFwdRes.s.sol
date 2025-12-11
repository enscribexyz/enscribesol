// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {NameSetter} from "../src/NameSetter.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

/// @title HelloWorldDeployAndSetFwdResScript
/// @notice Forge script to deploy HelloWorld and set its ENS primary name via NameSetter
contract HelloWorldDeployAndSetFwdResScript is Script {
    function run() public {
        vm.startBroadcast();

        // 1. Deploy the HelloWorld contract on-chain
        HelloWorld hello = new HelloWorld("hi forge!", 0);

        // 2. Register primary name for the deployed contract using NameSetter
        NameSetter.setForwardResolution(block.chainid, address(hello), "enscribesolfwdres11.abhi.eth");

        vm.stopBroadcast();
    }
}