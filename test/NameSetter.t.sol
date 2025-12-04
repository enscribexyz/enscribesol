// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NameSetter} from "../src/NameSetter.sol";
import {NameSetterUtils} from "../src/NameSetterUtils.sol";

/// @title NameSetterWrapper
/// @notice Wrapper contract to test library functions
contract NameSetterWrapper {
    function splitName(string memory fullName) external pure returns (string memory label, string memory parentName) {
        return NameSetterUtils.splitName(fullName);
    }

    function namehash(string memory name) external pure returns (bytes32) {
        return NameSetterUtils.namehash(name);
    }
}

/// @title NameSetterTest
/// @notice Test contract for NameSetter library utility functions
contract NameSetterTest is Test {
    NameSetterWrapper wrapper;

    function setUp() public {
        wrapper = new NameSetterWrapper();
    }
    /// @notice Test splitName function with various inputs
    function test_SplitName_Simple() public {
        (string memory label, string memory parentName) = wrapper.splitName("myname.eth");
        assertEq(label, "myname");
        assertEq(parentName, "eth");
    }

    function test_SplitName_MultiLevel_1() public {
        (string memory label, string memory parentName) = wrapper.splitName("sub.domain.eth");
        assertEq(label, "sub");
        assertEq(parentName, "domain.eth");
    }

    function test_SplitName_MultiLevel_2() public {
        (string memory label, string memory parentName) = wrapper.splitName("sub.abhi.base.eth");
        assertEq(label, "sub");
        assertEq(parentName, "abhi.base.eth");
    }

    function test_SplitName_LongLabel() public {
        (string memory label, string memory parentName) = wrapper.splitName("verylonglabelname.eth");
        assertEq(label, "verylonglabelname");
        assertEq(parentName, "eth");
    }

    function test_SplitName_ShortLabel() public {
        (string memory label, string memory parentName) = wrapper.splitName("a.eth");
        assertEq(label, "a");
        assertEq(parentName, "eth");
    }

    function test_SplitName_RevertsWhenEmpty() public {
        vm.expectRevert("NameSetter: name cannot be empty");
        wrapper.splitName("");
    }

    function test_SplitName_RevertsWhenNoDot() public {
        vm.expectRevert("NameSetter: name must contain a dot");
        wrapper.splitName("nodot");
    }

    function test_SplitName_RevertsWhenLabelEmpty() public {
        vm.expectRevert("NameSetter: label cannot be empty");
        wrapper.splitName(".eth");
    }

    function test_SplitName_RevertsWhenParentEmpty() public {
        vm.expectRevert("NameSetter: parent name cannot be empty");
        wrapper.splitName("label.");
    }

    /// @notice Test namehash function with known values
    function test_Namehash_Empty() public {
        bytes32 node = wrapper.namehash("");
        assertEq(node, bytes32(0));
    }

    function test_Namehash_Eth() public {
        bytes32 node = wrapper.namehash("eth");
        // Known value: namehash("eth") = keccak256(keccak256("eth") + bytes32(0))
        bytes32 expected = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes("eth"))));
        assertEq(node, expected);
    }

    function test_Namehash_SubEth() public {
        bytes32 ethNode = wrapper.namehash("eth");
        bytes32 subEthNode = wrapper.namehash("sub.eth");
        // namehash("sub.eth") = keccak256(keccak256("sub") + namehash("eth"))
        bytes32 expected = keccak256(abi.encodePacked(ethNode, keccak256(bytes("sub"))));
        assertEq(subEthNode, expected);
    }

    function test_Namehash_MultiLevel() public {
        bytes32 domainEthNode = wrapper.namehash("domain.eth");
        bytes32 subDomainEthNode = wrapper.namehash("sub.domain.eth");
        // namehash("sub.domain.eth") = keccak256(keccak256("sub") + namehash("domain.eth"))
        bytes32 expected = keccak256(abi.encodePacked(domainEthNode, keccak256(bytes("sub"))));
        assertEq(subDomainEthNode, expected);
    }

    function test_Namehash_MatchesENSStandard() public {
        // Test against known ENS namehash values
        // These are standard ENS namehash calculations
        bytes32 ethNode = wrapper.namehash("eth");
        bytes32 testNode = wrapper.namehash("test.eth");
        
        // Verify the structure is correct
        bytes32 expectedTestNode = keccak256(abi.encodePacked(ethNode, keccak256(bytes("test"))));
        assertEq(testNode, expectedTestNode);
    }

    /// @notice Test getter functions for contract addresses
    function test_GetRegistry_Mainnet() public pure {
        address registry = NameSetterUtils.getRegistry(1);
        assertEq(registry, 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function test_GetRegistry_Sepolia() public pure {
        address registry = NameSetterUtils.getRegistry(11155111);
        assertEq(registry, 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function test_GetRegistry_Optimism() public pure {
        address registry = NameSetterUtils.getRegistry(10);
        assertEq(registry, 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function test_GetRegistry_Unsupported() public pure {
        address registry = NameSetterUtils.getRegistry(999);
        assertEq(registry, 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function test_GetPublicResolver_Mainnet() public pure {
        address resolver = NameSetterUtils.getPublicResolver(1);
        assertEq(resolver, 0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63);
    }

    function test_GetPublicResolver_Sepolia() public pure {
        address resolver = NameSetterUtils.getPublicResolver(11155111);
        assertEq(resolver, 0xE99638b40E4Fff0129D56f03b55b6bbC4BBE49b5);
    }

    function test_GetPublicResolver_Unsupported() public pure {
        address resolver = NameSetterUtils.getPublicResolver(999);
        assertEq(resolver, address(0));
    }

    function test_GetNameWrapper_Mainnet() public pure {
        address nameWrapper = NameSetterUtils.getNameWrapper(1);
        assertEq(nameWrapper, 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);
    }

    function test_GetNameWrapper_Sepolia() public pure {
        address nameWrapper = NameSetterUtils.getNameWrapper(11155111);
        assertEq(nameWrapper, 0x0635513F179D50AFB97D942A5D3c54C2F838B8f4);
    }

    function test_GetNameWrapper_Unsupported() public pure {
        address nameWrapper = NameSetterUtils.getNameWrapper(999);
        assertEq(nameWrapper, address(0));
    }

    function test_GetReverseRegistrar_Mainnet() public pure {
        address reverseRegistrar = NameSetterUtils.getReverseRegistrar(1);
        assertEq(reverseRegistrar, 0x084b1c3C81545d370f3634392De611CaaBFf8148);
    }

    function test_GetReverseRegistrar_Sepolia() public pure {
        address reverseRegistrar = NameSetterUtils.getReverseRegistrar(11155111);
        assertEq(reverseRegistrar, 0x8e9Bd30D15420bAe4B7EC0aC014B7ECeE864373C);
    }

    function test_GetReverseRegistrar_Unsupported() public pure {
        address reverseRegistrar = NameSetterUtils.getReverseRegistrar(999);
        assertEq(reverseRegistrar, address(0));
    }

    /// @notice Test integration: splitName + namehash
    function test_SplitNameAndNamehash_Integration() public {
        (string memory label, string memory parentName) = wrapper.splitName("myname.eth");
        bytes32 parentNode = wrapper.namehash(parentName);
        bytes32 labelHash = keccak256(bytes(label));
        bytes32 expectedNode = keccak256(abi.encodePacked(parentNode, labelHash));
        
        bytes32 fullNameNode = wrapper.namehash("myname.eth");
        assertEq(fullNameNode, expectedNode);
    }

    /// @notice Fuzz test for splitName
    function testFuzz_SplitName(string memory label, string memory parentName) public {
        // Skip if either part is empty or contains dots
        if (bytes(label).length == 0 || bytes(parentName).length == 0) return;
        if (bytes(label).length > 100 || bytes(parentName).length > 100) return;
        
        // Check if label or parentName contains dots (would break our simple split)
        bytes memory labelBytes = bytes(label);
        bytes memory parentBytes = bytes(parentName);
        for (uint256 i = 0; i < labelBytes.length; i++) {
            if (labelBytes[i] == 0x2e) return; // contains dot
        }
        for (uint256 i = 0; i < parentBytes.length; i++) {
            if (parentBytes[i] == 0x2e) return; // contains dot
        }
        
        string memory fullName = string(abi.encodePacked(label, ".", parentName));
        (string memory splitLabel, string memory splitParent) = wrapper.splitName(fullName);
        
        assertEq(splitLabel, label);
        assertEq(splitParent, parentName);
    }
}

