//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Structs.sol";
import "./lib/Utils.sol";
import "./lib/Errors.sol";

contract WorldPool is ReentrancyGuard {

    uint _nonce;

    mapping(bytes32 => Structs.Pool) public pools;

    constructor() { _nonce = 0; }

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
        nonReentrant
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
        nonReentrant
        stringNotEmptyOrError(name)
        poolKeyExistsOrError(poolId)
        addressAuthorisedOrError(poolOwner, msg.sender)
    {
        Structs.Pool memory pool = pools[poolId];

        if (!Utils.compareStrings(pool.name, name)) {
            pool.name = name;
        }

        if (!Utils.compareStrings(pool.description, description)) {
            pool.description = description;
        }

        if (minStake != pool.minStake) {
            pool.minStake = minStake;
        }

        pools[poolId] = pool;
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
        nonReentrant
        poolKeyExistsOrError(poolId)
        addressAuthorisedOrError(poolOwner, msg.sender)
    {
        // TODO : Payout contributors
        // TODO : Payout admin

        delete pools[poolId];
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
}
