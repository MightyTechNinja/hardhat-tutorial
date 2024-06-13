//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "./IERC20.sol";
import "./SafeMath.sol";

struct Stake {
    uint256 totalBalance;
    uint256 rewards;
    uint256 lastUpdateTime;
    uint256[] balances;
    uint256[] initialTimes;
}

contract Staking {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public totalStake;
    uint256 public interestRate;

    mapping(address => Stake) public stakes;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        totalStake = 0;
        interestRate = 20;
    }

    event TokenStaked(address indexed staker, uint256 amount);
    event TokenUnstaked(address indexed staker, uint256 amount);
    event RewardPaid(address indexed staker, uint256 amount);

    function stakeTokens(uint256 value) external {
        require(value > 0, "Amount of tokens must be greater than 0");
        require(
            token.allowance(msg.sender, address(this)) >= value,
            "Allowance is not enough"
        );
        token.transferFrom(msg.sender, address(this), value);
        totalStake = totalStake.add(value);

        Stake storage stake = stakes[msg.sender];
        if (stake.totalBalance != 0) updateRewards(msg.sender);
        stake.totalBalance = stake.totalBalance.add(value);
        stake.balances.push(value);
        stake.initialTimes.push(block.timestamp);
        stake.lastUpdateTime = block.timestamp;

        emit TokenStaked(msg.sender, value);
    }

    function getStakeInfo()
        external
        view
        returns (uint256, uint256, uint256[] memory, uint256[] memory)
    {
        Stake memory stake = stakes[msg.sender];
        uint256 totalBalance = stake.totalBalance;
        uint256 rewards = calcRewards(msg.sender);
        uint256[] memory balances = stake.balances;
        uint256[] memory initialTimes = stake.initialTimes;
        return (totalBalance, rewards, balances, initialTimes);
    }

    function unstakeTokens(uint256 index) external {
        require(
            index < stakes[msg.sender].balances.length && index >= 0,
            "Index out of bounds"
        );
        require(
            block.timestamp >=
                stakes[msg.sender].initialTimes[index].add(30 days),
            "Locking period not over"
        );
        uint256 amount = stakes[msg.sender].balances[index];
        token.transfer(msg.sender, amount);
        totalStake = totalStake.sub(amount);

        Stake storage stake = stakes[msg.sender];
        updateRewards(msg.sender);
        stake.totalBalance = stake.totalBalance.sub(amount);
        stake.balances[index] = 0;
        stake.lastUpdateTime = block.timestamp;

        emit TokenUnstaked(msg.sender, amount);
    }

    function takeRewards() external {
        Stake storage stake = stakes[msg.sender];
        updateRewards(msg.sender);
        token.transfer(msg.sender, stake.rewards);
        stake.rewards = 0;
        stake.lastUpdateTime = block.timestamp;

        emit RewardPaid(msg.sender, stake.rewards);
    }

    function updateRewards(address staker) internal {
        Stake storage stake = stakes[staker];
        stake.rewards = calcRewards(staker);
    }

    function calcRewards(address staker) internal view returns (uint256) {
        Stake memory stake = stakes[staker];
        uint256 duration = block.timestamp.sub(stake.lastUpdateTime);
        uint256 rewards = duration
            .mul(interestRate)
            .mul(stake.totalBalance)
            .div(100)
            .div(365 * 24 * 60 * 60);
        return stake.rewards.add(rewards);
    }
}
