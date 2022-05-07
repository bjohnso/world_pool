import { expect } from "chai";
import { waffle } from "hardhat";

// eslint-disable-next-line node/no-missing-import
import { unitWorldPoolFixture } from "./fixtures/fixture";

// eslint-disable-next-line no-unused-vars,node/no-missing-import
import { WorldPool } from "../typechain";

describe("Unit Tests", async () => {
  before(async function () {
    const wallets = waffle.provider.getWallets();

    this.signers = {
      deployer: wallets[0],
      poolAdmin: wallets[1],
      user: wallets[2],
    };

    this.loadFixture = waffle.createFixtureLoader(wallets);
    const { worldPool } = await this.loadFixture(unitWorldPoolFixture);
    this.worldPool = worldPool;
  });

  describe("WorldPool", async () => {
    it("Should create new pool", async function () {
      const name = "African Union";
      const description =
        "The vision of the African Union is that of: “An integrated," +
        " prosperous and peaceful Africa, driven by its own citizens and " +
        "representing a dynamic force in global arena.” The African Union works " +
        "together with the European Commission Executive Agency on funding opportunities";
      const minStake = 1050975209;

      const tx = await this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool(name, description, minStake);

      const receipt = await tx.wait();

      for (const event of receipt.events) {
        console.log(event.event, event.args);
      }

      expect(receipt).to.emit(this.worldPool, "CreatePool");
    });
  });
});
