import { expect } from "chai";
import { ethers } from "hardhat";

export const worldPoolCreate = (): void => {
  context("#create", async function () {
    before(async function () {
      this.name = "Lorem Ipsum";
      this.description = "lorem ipsum";
      this.minStake = 1050975209;
    });

    it("Should fail to create pool due to EmptyString", async function () {
      const tx = this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool("", this.description, this.minStake);

      await expect(tx).to.be.revertedWith("EmptyString");
    });

    it("Should create pool", async function () {
      const tx = this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool(this.name, this.description, this.minStake);

      await expect(tx).to.be.emit(this.worldPool, "CreatePool");
    });
  });
};

export const worldPoolUpdate = (): void => {
  context("#update", async function () {
    before(async function () {
      this.name = "Lorem Ipsum";
      this.description = "lorem ipsum";
      this.minStake = 1050975209;

      this.newName = "Dolar Sit Amet";
      this.newDescription = "dolar sit amet";
      this.newMinStake = this.minStake * 2;
    });

    beforeEach(async function () {
      const tx = await this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool(this.name, this.description, this.minStake);

      const receipt = await tx.wait();

      this.poolId = receipt.events[0].args[0];
      this.poolOwner = receipt.events[0].args[1];
    });

    it("Should fail to update pool due to EmptyString", async function () {
      const tx = this.worldPool
        .connect(this.signers.poolAdmin)
        .updatePool(this.poolId, "", this.newDescription, this.newMinStake);

      await expect(tx).to.be.revertedWith("EmptyString");
    });

    it("Should fail to update pool due to KeyNotFound", async function () {
      const unknownKey = ethers.utils.formatBytes32String("notFoundKey");

      const tx = this.worldPool
        .connect(this.signers.poolAdmin)
        .updatePool(
          unknownKey,
          this.newName,
          this.newDescription,
          this.newMinStake
        );

      await expect(tx).to.be.revertedWith("KeyNotFound");
    });

    it("Should fail to update pool due to AddressUnauthorised", async function () {
      const tx = this.worldPool
        .connect(this.signers.unauthorised)
        .updatePool(
          this.poolId,
          this.newName,
          this.newDescription,
          this.newMinStake
        );

      await expect(tx).to.be.revertedWith("AddressUnauthorised");
    });

    it("Should update pool", async function () {
      const tx = this.worldPool
        .connect(this.signers.poolAdmin)
        .updatePool(
          this.poolId,
          this.newName,
          this.newDescription,
          this.newMinStake
        );

      await expect(tx).to.be.emit(this.worldPool, "UpdatePool");
    });
  });
};
