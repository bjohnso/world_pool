//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WorldPool is ReentrancyGuard {

    uint _nonce;

    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => PoolDepositEscrow) public poolDepositEscrows;

    constructor() { _nonce = 0; }

    function createPool(string memory name, string memory description, uint256 minStake) public {
        bytes32 poolId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));
        address owner = msg.sender;

        require(
            pools[poolId].owner == address(0x0),
            "Could not generate unique Pool ID."
        );

        require(
            bytes(name).length > 0,
            "Pool name can not be empty."
        );

        Pool memory pool = Pool({
            id: poolId,
            owner: owner,
            name: name,
            description: description,
            balance: 0,
            minStake: minStake
        });

        pools[poolId] = pool;
    }

    function updatePool(bytes32 poolId, string memory name, string memory description, uint256 minStake) public {
        address owner = msg.sender;

        require(
            pools[poolId].owner != address(0x0),
            "No Pool exists for this ID."
        );

        require(
            pools[poolId].owner == owner,
            "A transaction signer must own the Pool they wish to update."
        );

        require(
            bytes(name).length > 0,
            "Pool name can not be empty."
        );

        Pool memory pool = pools[poolId];

        if (!compareStrings(pool.name, name)) {
            pool.name = name;
        }

        if (!compareStrings(pool.description, description)) {
            pool.description = description;
        }

        if (minStake != pool.minStake) {
            pool.minStake = minStake;
        }

        pools[poolId] = pool;
    }

    function deletePool(bytes32 poolId) {
        address owner = msg.sender;

        require(
            pools[poolId].owner != address(0x0),
            "No Pool exists for this ID."
        );

        require(
            pools[poolId].owner == owner,
            "A transaction signer must own the Pool they wish to delete."
        );

        // TODO : Payout contributors
        // TODO : Payout admin

        delete pools[poolId];
    }

    function createUserEscrow(bytes32 poolId) public payable {
        bytes32 escrowId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));

        require(
            pools[poolId].owner != address(0x0),
            "No Pool exists for this ID."
        );

        require(
            poolDepositEscrows[escrowId].owner == address(0x0),
            "Could not generate unique Pool Deposit Escrow ID."
        );

        require(
            pools[poolId].minStake <= msg.value,
            "Deposit does not meet the minimum requirement."
        );

        PoolDepositEscrow memory poolDepositEscrow = PoolDepositEscrow({
            id: escrowId,
            owner: owner,
            poolId: poolId,
            balance: 0
        });

        poolDepositEscrow.balance += msg.value;
        poolDepositEscrows[escrowId] = poolDepositEscrow;
    }

    function depositIntoUserEscrow(bytes escrowId) public payable {
        PoolDepositEscrow memory poolDepositEscrow = poolDepositEscrows[escrowId];

        require(
            poolDepositEscrow.owner != address(0x0),
            "No Pool Deposit Escrow exists for this ID."
        );

        bytes32 poolId = poolDepositEscrow.poolId;

        require(
            pools[poolId].owner != address(0x0),
            "No Pool exists for this ID."
        );

        poolDepositEscrow.balance += msg.value;
        poolDepositEscrows[escrowId] = poolDepositEscrow;
    }

    function compareStrings (string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    struct Pool {
        bytes32 id; // pool Id
        address owner; // pool owner
        string name; // pool name
        string description; // pool description
        uint256 balance; // staked amount in wei
        uint256 minStake; // minimum amount staked
    }

    struct PoolDepositEscrow {
        bytes32 id; // escrow Id
        address owner; // owner of deposited funds
        bytes32 poolId; // pool Id
        uint256 balance; // staked amount in wei
    }
}
