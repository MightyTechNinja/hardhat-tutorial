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

      await expect(contract.stakeTokens(10000)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [-10000, 10000]
      );

      const oneMonth = 30 * 24 * 60 * 60;
      await ethers.provider.send("evm_increaseTime", [oneMonth]);
      await ethers.provider.send("evm_mine");

      await expect(contract.unstakeTokens(0)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [10000, -10000]
      );
    });

    it("Should take rewards", async function () {
      const { hardhatToken, contract, owner } = await loadFixture(
        deployTokenAndStakingFixture
      );

      await hardhatToken.approve(contract.target, 10000);

      await expect(contract.stakeTokens(10000)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [-10000, 10000]
      );

      const oneMonth = 30 * 24 * 60 * 60;
      await ethers.provider.send("evm_increaseTime", [oneMonth]);
      await ethers.provider.send("evm_mine");

      await expect(contract.takeRewards()).to.changeTokenBalances(
        hardhatToken,
        [owner],
        [Math.floor((10000 * 20 * 30) / 365 / 100)]
      );
    });

    it("Should get stakeinfo", async function () {
      const { hardhatToken, contract, owner } = await loadFixture(
        deployTokenAndStakingFixture
      );

      await hardhatToken.approve(contract.target, 10000);

      await expect(contract.stakeTokens(10000)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [-10000, 10000]
      );

      await hardhatToken.approve(contract.target, 5000);

      await expect(contract.stakeTokens(5000)).to.changeTokenBalances(
        hardhatToken,
        [owner, contract],
        [-5000, 5000]
      );

      const oneMonth = 30 * 24 * 60 * 60;
      await ethers.provider.send("evm_increaseTime", [oneMonth]);
      await ethers.provider.send("evm_mine");

      await contract.unstakeTokens(0);

      const info = await contract.getStakeInfo();
      expect(info[0]).to.equal(5000);
    });
  });
});
