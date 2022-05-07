//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WorldPool.sol";
import "./lib/Structs.sol";
import "./lib/Errors.sol";

contract Escrow is ReentrancyGuard {
    uint _nonce;

    WorldPool worldPoolContract;

    constructor() { _nonce = 0; }

    mapping(bytes32 => Structs.Escrow) public escrows;

    function External(address worldPoolContractAddress) public {
        worldPoolContract = WorldPool(worldPoolContractAddress);
    }

    function create(bytes32 poolId)
        public
        payable
        poolKeyExistsOrError(poolId)
        validStakeOrError(poolId, msg.value)
    {
        bytes32 escrowId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));
        create(poolId, escrowId);
    }

    function create(bytes32 poolId, bytes32 escrowId)
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
    }

    function deposit(bytes32 escrowId)
        public
        payable
        escrowKeyExistsOrError(escrowId)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        deposit(escrowId, escrow.poolId, escrow.owner);
    }

    function deposit(bytes32 escrowId, bytes32 poolId, address owner)
        private
        escrowKeyExistsOrError(escrowId)
        poolKeyExistsOrError(poolId)
        addressAuthorisedOrError(owner, msg.sender)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        escrow.balance += msg.value;
        escrows[escrowId] = escrow;
    }

    function withdraw(bytes32 escrowId, uint256 withdrawAmount)
        public
        escrowKeyExistsOrError(escrowId)
        validWithdrawAmountOrError(escrowId, withdrawAmount)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        withdraw(escrowId, withdrawAmount, escrow.owner);
    }

    function withdraw(bytes32 escrowId, uint256 withdrawAmount, address owner)
        private
        escrowKeyExistsOrError(escrowId)
        validWithdrawAmountOrError(escrowId, withdrawAmount)
        addressAuthorisedOrError(owner, msg.sender)
        withdrawOrError(withdrawAmount)
    {
        Structs.Escrow memory escrow = escrows[escrowId];
        escrow.balance -= withdrawAmount;
        escrows[escrowId] = escrow;
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

    modifier stringNotEmptyOrError(string memory str) {
        if (bytes(str).length < 1) {
            revert Errors.EmptyString();
        }

        _;
    }

    modifier validStakeOrError(bytes32 poolId, uint256 stake) {
        Structs.Pool memory pool = worldPoolContract.getPool(poolId);

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

    modifier poolKeyExistsOrError(bytes32 poolId) {
        Structs.Pool memory pool = worldPoolContract.getPool(poolId);

        if (pool.owner == address(0x0)) {
            revert Errors.KeyNotFound();
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
}
