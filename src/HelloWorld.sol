// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title HelloWorld
/// @notice Ownable hello-world style contract used for integration testing with Ens
contract HelloWorld is Ownable {
    string greetings;
    uint256 count;

    constructor(string memory greet, uint256 initialCount) Ownable(msg.sender) {
        greetings = greet;
        count = initialCount;
    }

    function set(string memory greet) public {
        greetings = greet;
    }

    function retrieve() public view returns (string memory) {
        return greetings;
    }
}
