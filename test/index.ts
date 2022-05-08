import { waffle } from "hardhat";

// eslint-disable-next-line node/no-missing-import
import { unitEscrowFixture, unitWorldPoolFixture } from "./fixtures/fixture";

// eslint-disable-next-line no-unused-vars,node/no-missing-import
import { WorldPool, Escrow } from "../typechain";

// eslint-disable-next-line node/no-missing-import
import {
  worldPoolCreate,
  worldPoolDelete,
  worldPoolUpdate,
  // eslint-disable-next-line node/no-missing-import
} from "./world_pool/WorldPool.spec";

import {
  escrowContractInit,
  escrowCreate,
  escrowDeposit,
  escrowWithdraw,
  // eslint-disable-next-line node/no-missing-import
} from "./escrow/Escrow.spec";

describe("Unit Tests", async () => {
  before(async function () {
    const wallets = waffle.provider.getWallets();

    this.signers = {
      deployer: wallets[0],
      poolAdmin: wallets[1],
      user: wallets[2],
      unauthorised: wallets[10],
    };

    this.loadFixture = waffle.createFixtureLoader(wallets);
  });

  describe("WorldPool", async () => {
    beforeEach(async function () {
      const { worldPool } = await this.loadFixture(unitWorldPoolFixture);
      this.worldPool = worldPool;
    });

    worldPoolCreate();
    worldPoolUpdate();
    worldPoolDelete();
  });

  describe("Escrow", async function () {
    beforeEach(async function () {
      const { escrow, worldPool } = await this.loadFixture(unitEscrowFixture);
      this.worldPool = worldPool;
      this.escrow = escrow;
    });

    escrowContractInit();
    escrowCreate();
    escrowDeposit();
    escrowWithdraw();
  });
});
