import { Fixture } from "ethereum-waffle";
import { ContractFactory, Wallet } from "ethers";
import { ethers } from "hardhat";

// eslint-disable-next-line node/no-missing-import
import { Escrow, WorldPool } from "../../typechain";

type UnitWorldPoolFixtureType = {
  worldPool: WorldPool;
};

type UnitEscrowFixtureType = {
  escrow: Escrow;
  worldPool: WorldPool;
};

export const unitWorldPoolFixture: Fixture<UnitWorldPoolFixtureType> = async (
  signers: Wallet[]
) => {
  const deployer: Wallet = signers[0];
  const worldPoolFactory: ContractFactory = await ethers.getContractFactory(
    `WorldPool`
  );

  const worldPool: WorldPool = (await worldPoolFactory
    .connect(deployer)
    .deploy()) as WorldPool;

  await worldPool.deployed();

  return { worldPool };
};

export const unitEscrowFixture: Fixture<UnitEscrowFixtureType> = async (
  signers: Wallet[]
) => {
  const deployer: Wallet = signers[0];
  const escrowFactory: ContractFactory = await ethers.getContractFactory(
    `Escrow`
  );

  const worldPoolFactory: ContractFactory = await ethers.getContractFactory(
    `WorldPool`
  );

  const escrow: Escrow = (await escrowFactory
    .connect(deployer)
    .deploy()) as Escrow;

  const worldPool: WorldPool = (await worldPoolFactory
    .connect(deployer)
    .deploy()) as WorldPool;

  await escrow.deployed();
  await worldPool.deployed();

  return { escrow, worldPool };
};
