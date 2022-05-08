import { expect } from "chai";
import { ethers } from "hardhat";

export const escrowContractInit = (): void => {
  context("#contractInit", async function () {
    it("Should fail to init world pool contract address due to UnauthorisedAddress", async function () {
      const tx = this.escrow
        .connect(this.signers.unauthorised)
        .initWorldPoolContract(this.worldPool.address);

      await expect(tx).to.be.reverted;
    });

    it("Should init world pool contract address", async function () {
      const tx = this.escrow
        .connect(this.signers.deployer)
        .initWorldPoolContract(this.worldPool.address);

      await expect(tx).to.be.emit(this.escrow, "InitWorldPoolContract");
    });
  });
};

export const escrowCreate = (): void => {
  context("#create", async function () {
    before(async function () {
      this.name = "Lorem Ipsum";
      this.description = "lorem ipsum";
      this.minStake = 1050975209;
    });

    beforeEach(async function () {
      const worldPoolTx = await this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool(this.name, this.description, this.minStake);

      const worldPoolEmissions = await worldPoolTx.wait();

      this.poolId = worldPoolEmissions.events[0].args[0];

      const escrowTx = await this.escrow
        .connect(this.signers.deployer)
        .initWorldPoolContract(this.worldPool.address);

      await escrowTx.wait();
    });

    it("Should fail to create escrow due to KeyNotFound", async function () {
      const unknownKey = ethers.utils.formatBytes32String("notFoundKey");

      const tx = this.escrow
        .connect(this.signers.user)
        .create(unknownKey, { value: this.minStake });
      await expect(tx).to.be.revertedWith("KeyNotFound");
    });

    it("Should fail to create escrow due to InsufficientStake", async function () {
      const tx = this.escrow
        .connect(this.signers.user)
        .create(this.poolId, { value: 1 });
      await expect(tx).to.be.revertedWith("InsufficientStake");
    });

    it("Should create escrow", async function () {
      const tx = this.escrow
        .connect(this.signers.user)
        .create(this.poolId, { value: this.minStake });

      await expect(tx).to.be.emit(this.escrow, "CreateEscrow");
    });
  });
};

export const escrowDeposit = (): void => {
  context("#deposit", async function () {
    before(async function () {
      this.name = "Lorem Ipsum";
      this.description = "lorem ipsum";
      this.minStake = 1050975209;
    });

    beforeEach(async function () {
      const worldPoolTx = await this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool(this.name, this.description, this.minStake);

      const worldPoolReceipt = await worldPoolTx.wait();

      this.poolId = worldPoolReceipt.events[0].args[0];

      const escrowTx = await this.escrow
        .connect(this.signers.deployer)
        .initWorldPoolContract(this.worldPool.address);

      await escrowTx.wait();

      const escrowCreateTx = await this.escrow
        .connect(this.signers.user)
        .create(this.poolId, { value: this.minStake });

      const escrowCreateEmission = await escrowCreateTx.wait();

      this.escrowId = escrowCreateEmission.events[0].args[0];
    });

    it("Should fail to deposit into escrow due to KeyNotFound", async function () {
      const unknownKey = ethers.utils.formatBytes32String("notFoundKey");

      const tx = this.escrow
        .connect(this.signers.user)
        .deposit(unknownKey, { value: 1 });

      await expect(tx).to.be.revertedWith("KeyNotFound");
    });

    it("Should fail to deposit into escrow due to AddressUnauthorised", async function () {
      const tx = this.escrow
        .connect(this.signers.unauthorised)
        .deposit(this.escrowId, { value: 1 });

      await expect(tx).to.be.revertedWith("AddressUnauthorised");
    });

    it("Should deposit into escrow", async function () {
      const tx = this.escrow
        .connect(this.signers.user)
        .deposit(this.escrowId, { value: 1 });

      await expect(tx).to.be.emit(this.escrow, "DepositEscrow");
    });
  });
};

export const escrowWithdraw = (): void => {
  context("#withdraw", async function () {
    before(async function () {
      this.name = "Lorem Ipsum";
      this.description = "lorem ipsum";
      this.minStake = 1050975209;
    });

    beforeEach(async function () {
      const worldPoolTx = await this.worldPool
        .connect(this.signers.poolAdmin)
        .createPool(this.name, this.description, this.minStake);

      const worldPoolReceipt = await worldPoolTx.wait();

      this.poolId = worldPoolReceipt.events[0].args[0];

      const escrowTx = await this.escrow
        .connect(this.signers.deployer)
        .initWorldPoolContract(this.worldPool.address);

      await escrowTx.wait();

      const escrowCreateTx = await this.escrow
        .connect(this.signers.user)
        .create(this.poolId, { value: this.minStake });

      const escrowCreateEmission = await escrowCreateTx.wait();

      this.escrowId = escrowCreateEmission.events[0].args[0];
      this.escrowBalance = escrowCreateEmission.events[0].args[3];
    });

    it("Should fail to withdraw from escrow due to KeyNotFound", async function () {
      const unknownKey = ethers.utils.formatBytes32String("notFoundKey");

      const tx = this.escrow
        .connect(this.signers.user)
        .withdraw(unknownKey, this.escrowBalance);

      await expect(tx).to.be.revertedWith("KeyNotFound");
    });

    it("Should fail to withdraw from escrow due to InsufficientBalance", async function () {
      const tx = this.escrow
        .connect(this.signers.user)
        .withdraw(this.escrowId, this.escrowBalance + 1);

      await expect(tx).to.be.revertedWith("InsufficientBalance");
    });

    it("Should fail to withdraw from escrow due to AddressUnauthorised", async function () {
      const tx = this.escrow
        .connect(this.signers.unauthorised)
        .withdraw(this.escrowId, this.escrowBalance);

      await expect(tx).to.be.revertedWith("AddressUnauthorised");
    });

    it("Should withdraw from escrow", async function () {
      const tx = this.escrow
        .connect(this.signers.user)
        .withdraw(this.escrowId, this.escrowBalance);

      await expect(tx).to.be.emit(this.escrow, "WithdrawEscrow");
    });
  });
};
