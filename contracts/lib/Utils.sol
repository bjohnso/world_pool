//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library Utils {
    function compareStrings (string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
