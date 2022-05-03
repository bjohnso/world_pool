//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WorldPool is ReentrancyGuard {

    uint _nonce;

    mapping(bytes32 => Pool) public pools;

    constructor() { _nonce = 0; }

    function createPool(string memory name, string memory description) public {
        bytes32 poolId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));
        address owner = msg.sender;

        require(
            pools[poolId].owner == address(0x0),
            "Could not generate unique Pool Id."
        );

        Pool memory pool = Pool({
            id: poolId,
            owner: owner,
            name: name,
            description: description,
            balance: 0
        });

        pools[poolId] = pool;
    }

    struct Pool {
        bytes32 id; // pool Id
        address owner; // pool owner
        string name; // pool name
        string description; // pool description
        uint256 balance; // staked amount in wei
    }
}
