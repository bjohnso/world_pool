//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library Structs {
    struct Pool {
        bytes32 id; // pool Id
        address owner; // pool owner
        string name; // pool name
        string description; // pool description
        uint256 balance; // staked amount in wei
        uint256 minStake; // minimum amount staked
    }

    struct Escrow {
        bytes32 id; // escrow Id
        address owner; // owner of deposited funds
        bytes32 poolId; // pool Id
        uint256 balance; // staked amount in wei
    }
}
