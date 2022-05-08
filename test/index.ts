import { waffle } from "hardhat";

// eslint-disable-next-line node/no-missing-import
import { unitWorldPoolFixture } from "./fixtures/fixture";

// eslint-disable-next-line no-unused-vars,node/no-missing-import
import { WorldPool } from "../typechain";

// eslint-disable-next-line node/no-missing-import
import { worldPoolCreate, worldPoolUpdate } from "./world_pool/WorldPool.spec";

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
  });
});
