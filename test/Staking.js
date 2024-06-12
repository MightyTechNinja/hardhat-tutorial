const { expect } = require("chai");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Staking contract", function () {
  async function deployTokenAndStakingFixture() {
    const [owner] = await ethers.getSigners();
    const hardhatToken = await ethers.deployContract("NinjaToken");
    await hardhatToken.waitForDeployment();
    const stakingContract = await ethers.getContractFactory("Staking");
    const contract = await stakingContract.deploy(hardhatToken.target);
    await contract.waitForDeployment();
    return { hardhatToken, contract, owner };
  }

  describe("Deployment", function () {
    it("Should assign the NinjaToken to token", async function () {
      const { hardhatToken, contract } = await loadFixture(
        deployTokenAndStakingFixture
      );
      expect(await contract.token()).to.equal(hardhatToken.target);
    });
  });

  describe("Transactions", function () {
    it("Should stake and unstake tokens", async function () {
      const { hardhatToken, contract, owner } = await loadFixture(
        deployTokenAndStakingFixture
      );

      await hardhatToken.approve(contract.target, 10000);

      await expect(contract.stake(10000)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [-10000, 10000]
      );

      const oneMonth = 30 * 24 * 60 * 60;
      await ethers.provider.send("evm_increaseTime", [oneMonth]);
      await ethers.provider.send("evm_mine");

      await expect(contract.unstake(0)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [10000, -10000]
      );
    });

    it("Should get rewards", async function () {
      const { hardhatToken, contract, owner } = await loadFixture(
        deployTokenAndStakingFixture
      );

      await hardhatToken.approve(contract.target, 10000);

      await expect(contract.stake(10000)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [-10000, 10000]
      );

      const oneMonth = 30 * 24 * 60 * 60;
      await ethers.provider.send("evm_increaseTime", [oneMonth]);
      await ethers.provider.send("evm_mine");

      await expect(contract.getReward(0)).to.changeTokenBalances(
        hardhatToken,
        [owner],
        [Math.floor((10000 * 20 * 30) / 365 / 100)]
      );
    });

    it("Should emit Staked events", async function () {
      const { hardhatToken, contract, owner } = await loadFixture(
        deployTokenAndStakingFixture
      );

      await hardhatToken.approve(contract.target, 10000);
      await expect(contract.stake(10000))
        .to.emit(contract, "Staked")
        .withArgs(owner.address, 10000);
    });
  });
});
