//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Structs.sol";
import "./lib/Errors.sol";

contract WorldPool is ReentrancyGuard {

    uint256 private _nonce;

    mapping(bytes32 => Structs.Pool) public pools;

    constructor() { _nonce = 1; }

    function getPool(bytes32 poolId) public view returns (Structs.Pool memory) {
        return pools[poolId];
    }

    function createPool(string memory name, string memory description, uint256 minStake)
        public
        nonReentrant
    {
        bytes32 poolId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));
        createPool(name, description, minStake, poolId);
    }

    function createPool(string memory name, string memory description, uint256 minStake, bytes32 poolId)
        private
        stringNotEmptyOrError(name)
        uniquePoolKeyOrError(poolId)
    {
        address owner = msg.sender;

        Structs.Pool memory pool = Structs.Pool({
            id: poolId,
            owner: owner,
            name: name,
            description: description,
            balance: 0,
            minStake: minStake
        });

        pools[poolId] = pool;

        emit CreatePool(
            pool.id,
            pool.owner,
            pool.name,
            pool.description,
            pool.balance,
            pool.minStake
        );
    }

    function updatePool(bytes32 poolId, string memory name, string memory description, uint256 minStake)
        public
        nonReentrant
        poolKeyExistsOrError(poolId)
    {
        Structs.Pool memory pool = pools[poolId];
        updatePool(poolId, name, description, minStake, pool.owner);
    }

    function updatePool(
        bytes32 poolId,
        string memory name,
        string memory description,
        uint256 minStake,
        address poolOwner
    )
        private
        stringNotEmptyOrError(name)
        poolKeyExistsOrError(poolId)
        addressAuthorisedOrError(poolOwner, msg.sender)
    {
        Structs.Pool memory pool = pools[poolId];

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

        emit UpdatePool(
            pool.id,
            pool.owner,
            pool.name,
            pool.description,
            pool.balance,
            pool.minStake
        );
    }

    function deletePool(bytes32 poolId)
        public
        nonReentrant
        poolKeyExistsOrError(poolId)
    {
        Structs.Pool memory pool = pools[poolId];
        deletePool(poolId, pool.owner);
    }

    function deletePool(bytes32 poolId, address poolOwner)
        private
        poolKeyExistsOrError(poolId)
        addressAuthorisedOrError(poolOwner, msg.sender)
    {
        // TODO : Payout contributors
        // TODO : Payout admin

        Structs.Pool memory pool = pools[poolId];

        delete pools[poolId];

        emit DeletePool(
            pool.id,
            pool.owner,
            pool.name,
            pool.description,
            pool.balance,
            pool.minStake
        );
    }

    // Util

    function compareStrings (string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Mods

    modifier addressAuthorisedOrError(address auth, address a) {
        if (auth != a) {
            revert Errors.AddressUnauthorised();
        }

        _;
    }

    modifier addressExistsOrError(address a) {
        if (a == address(0x0)) {
            revert Errors.AddressNotFound();
        }

        _;
    }

    modifier uniquePoolKeyOrError(bytes32 poolId) {
        if (pools[poolId].owner != address(0x0)) {
            revert Errors.KeyNotUnique();
        }

        _;
    }

    modifier poolKeyExistsOrError(bytes32 poolId) {
        if (pools[poolId].owner == address(0x0)) {
            revert Errors.KeyNotFound();
        }

        _;
    }

    modifier stringNotEmptyOrError(string memory str) {
        if (bytes(str).length < 1) {
            revert Errors.EmptyString();
        }

        _;
    }

    // Events

    event CreatePool(
        bytes32 id, // pool Id
        address owner, // pool owner
        string name, // pool name
        string description, // pool description
        uint256 balance, // staked amount in wei
        uint256 minStake // minimum amount staked
    );

    event UpdatePool(
        bytes32 id, // pool Id
        address owner, // pool owner
        string name, // pool name
        string description, // pool description
        uint256 balance, // staked amount in wei
        uint256 minStake // minimum amount staked
    );

    event DeletePool(
        bytes32 id, // pool Id
        address owner, // pool owner
        string name, // pool name
        string description, // pool description
        uint256 balance, // staked amount in wei
        uint256 minStake // minimum amount staked
    );
}
