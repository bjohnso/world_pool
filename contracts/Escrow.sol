//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Structs.sol";
import "./WorldPool.sol";

contract Escrow is ReentrancyGuard {
    uint _nonce;

    WorldPool worldPoolContract;

    constructor() { _nonce = 0; }

    mapping(bytes32 => Structs.Escrow) public poolDepositEscrows;

    function External(address worldPoolContractAddress) public {
        worldPoolContract = WorldPool(worldPoolContractAddress);
    }

    function createUserEscrow(bytes32 poolId) public payable {
        bytes32 escrowId = keccak256(abi.encodePacked(block.number, msg.data, _nonce++));

        Structs.Pool memory pool = worldPoolContract.getPool(poolId);

        require(
            pool.owner != address(0x0),
            "No Pool exists for this ID."
        );

        require(
            poolDepositEscrows[escrowId].owner == address(0x0),
            "Could not generate unique Pool Deposit Escrow ID."
        );

        require(
            pool.minStake <= msg.value,
            "Deposit does not meet the minimum requirement."
        );

        Structs.Escrow memory poolDepositEscrow = Structs.Escrow({
            id: escrowId,
            owner: msg.sender,
            poolId: poolId,
            balance: 0
        });

        poolDepositEscrow.balance += msg.value;
        poolDepositEscrows[escrowId] = poolDepositEscrow;
    }

    function depositIntoUserEscrow(bytes32 escrowId) public payable {
        Structs.Escrow memory poolDepositEscrow = poolDepositEscrows[escrowId];

        require(
            poolDepositEscrow.owner == msg.sender,
            "No Pool Deposit Escrow exists for this ID or is owned by this user."
        );

        bytes32 poolId = poolDepositEscrow.poolId;
        Structs.Pool memory pool = worldPoolContract.getPool(poolId);

        require(
            pool.owner != address(0x0),
            "No Pool exists for this ID."
        );

        poolDepositEscrow.balance += msg.value;
        poolDepositEscrows[escrowId] = poolDepositEscrow;
    }

    function withdrawFromUserEscrow(bytes32 escrowId, uint256 withdrawAmount) public {
        Structs.Escrow memory poolDepositEscrow = poolDepositEscrows[escrowId];

        require(
            poolDepositEscrow.owner == msg.sender,
            "No Pool Deposit Escrow exists for this ID or is owned by this user."
        );

        bytes32 poolId = poolDepositEscrow.poolId;
        Structs.Pool memory pool = worldPoolContract.getPool(poolId);

        require(
            pool.owner != address(0x0),
            "No Pool exists for this ID."
        );

        require(
            poolDepositEscrow.balance >= withdrawAmount,
            "Insufficient balance in Escrow."
        );

        poolDepositEscrow.balance -= withdrawAmount;
        poolDepositEscrows[escrowId] = poolDepositEscrow;

        (bool sent,) = msg.sender.call{ value: withdrawAmount }("");

        require(
            sent,
            "Withdraw failed."
        );
    }
}
