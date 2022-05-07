import { Fixture } from "ethereum-waffle";
import { ContractFactory, Wallet } from "ethers";
import { ethers } from "hardhat";

// eslint-disable-next-line node/no-missing-import
import { WorldPool } from "../../typechain";

type UnitWorldPoolFixtureType = {
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
