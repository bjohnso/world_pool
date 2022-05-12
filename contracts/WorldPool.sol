//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Structs.sol";
import "./lib/Errors.sol";

contract WorldPool is ReentrancyGuard {

    uint256 private _nonce;

    mapping(bytes32 => Structs.Pool) public pools;
    mapping(bytes32 => Structs.Escrow) public escrows;

    constructor() { _nonce = 1; }

    // Pools

    function getPool(bytes32 poolId) public view returns (Structs.Pool memory) {
        return pools[poolId];
    }

    function getEscrow(bytes32 escrowId) public view returns (Structs.Escrow memory) {
        return escrows[escrowId];
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

    // Escrows

    function createEscrow(bytes32 poolId)
        public
        payable
        nonReentrant
        poolKeyExistsOrError(poolId)
        validStakeOrError(poolId, msg.value)
    {
        bytes32 escrowId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));
        createEscrow(poolId, escrowId);
    }

    function createEscrow(bytes32 poolId, bytes32 escrowId)
        private
        poolKeyExistsOrError(poolId)
        validStakeOrError(poolId, msg.value)
        uniqueEscrowKeyOrError(escrowId)
    {
        escrows[escrowId] = Structs.Escrow({
            id: escrowId,
            owner: msg.sender,
            poolId: poolId,
            balance: msg.value
        });

        Structs.Pool memory pool = pools[poolId];
        pool.balance += msg.value;
        pools[poolId] = pool;

        emit CreateEscrow(
            escrowId,
            msg.sender,
            poolId,
            msg.value
        );
    }

    function depositEscrow(bytes32 escrowId)
        public
        payable
        nonReentrant
        escrowKeyExistsOrError(escrowId)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        depositEscrow(escrowId, escrow.poolId, escrow.owner);
    }

    function depositEscrow(bytes32 escrowId, bytes32 poolId, address owner)
        private
        escrowKeyExistsOrError(escrowId)
        poolKeyExistsOrError(poolId)
        addressAuthorisedOrError(owner, msg.sender)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        escrow.balance += msg.value;
        escrows[escrowId] = escrow;

        Structs.Pool memory pool = pools[poolId];
        pool.balance += msg.value;
        pools[poolId] = pool;

        emit DepositEscrow(
            escrow.id,
            escrow.owner,
            escrow.poolId,
            escrow.balance
        );
    }

    function withdrawEscrow(bytes32 escrowId, uint256 withdrawAmount)
        public
        nonReentrant
        escrowKeyExistsOrError(escrowId)
        validWithdrawAmountOrError(escrowId, withdrawAmount)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        withdrawEscrow(escrowId, withdrawAmount, escrow.owner);
    }

    function withdrawEscrow(bytes32 escrowId, uint256 withdrawAmount, address owner)
        private
        escrowKeyExistsOrError(escrowId)
        validWithdrawAmountOrError(escrowId, withdrawAmount)
        addressAuthorisedOrError(owner, msg.sender)
        withdrawOrError(withdrawAmount)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        escrow.balance -= withdrawAmount;
        escrows[escrowId] = escrow;

        //TODO: VALIDATE POOL BALANCE
        bytes32 poolId = escrow.poolId;

        Structs.Pool memory pool = pools[poolId];
        pool.balance -= msg.value;
        pools[poolId] = pool;

        emit WithdrawEscrow(
            escrow.id,
            escrow.owner,
            escrow.poolId,
            escrow.balance
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

    modifier uniqueEscrowKeyOrError(bytes32 escrowId) {
        if (escrows[escrowId].owner != address(0x0)) {
            revert Errors.KeyNotUnique();
        }

        _;
    }

    modifier escrowKeyExistsOrError(bytes32 escrowId) {
        if (escrows[escrowId].owner == address(0x0)) {
            revert Errors.KeyNotFound();
        }

        _;
    }

    modifier validStakeOrError(bytes32 poolId, uint256 stake) {
        Structs.Pool memory pool = pools[poolId];

        if (pool.minStake > stake) {
            revert Errors.InsufficientStake();
        }

        _;
    }

    modifier validWithdrawAmountOrError(bytes32 escrowId, uint256 withdrawAmount) {
        Structs.Escrow memory escrow = escrows[escrowId];

        if (escrow.balance < withdrawAmount) {
            revert Errors.InsufficientBalance();
        }

        _;
    }

    modifier withdrawOrError(uint256 withdrawAmount) {
        (bool sent,) = msg.sender.call{ value: withdrawAmount }("");

        if (!sent) {
            revert Errors.WithdrawalFailed();
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

    event CreateEscrow(
        bytes32 id,
        address owner,
        bytes32 poolId,
        uint256 balance
    );

    event DepositEscrow(
        bytes32 id,
        address owner,
        bytes32 poolId,
        uint256 balance
    );

    event WithdrawEscrow(
        bytes32 id,
        address owner,
        bytes32 poolId,
        uint256 balance
    );
}
