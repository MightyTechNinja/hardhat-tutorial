//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "./IERC20.sol";
import "./SafeMath.sol";

contract Staking {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public totalStake;
    uint256 public interestRate;

    mapping(address => uint256[]) stakes;
    mapping(address => uint256[]) initialTimes;
    mapping(address => uint256[]) updatedTimes;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        totalStake = 0;
        interestRate = 20;
    }

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardPaid(address indexed staker, uint256 amount);

    function stake(uint256 value) external {
        require(value > 0, "Amount of tokens must be greater than 0");
        require(
            token.allowance(msg.sender, address(this)) >= value,
            "Allowance is not enough"
        );
        token.transferFrom(msg.sender, address(this), value);
        totalStake = totalStake.add(value);
        stakes[msg.sender].push(value);
        initialTimes[msg.sender].push(block.timestamp);
        updatedTimes[msg.sender].push(block.timestamp);

        emit Staked(msg.sender, value);
    }

    function unstake(uint256 index) external {
        require(
            index < stakes[msg.sender].length && index >= 0,
            "Index out of bounds"
        );
        require(
            block.timestamp >= initialTimes[msg.sender][index].add(30 days),
            "Locking period not over"
        );
        token.transfer(msg.sender, stakes[msg.sender][index]);
        totalStake = totalStake.sub(stakes[msg.sender][index]);

        delete stakes[msg.sender][index];
        delete initialTimes[msg.sender][index];
        delete updatedTimes[msg.sender][index];

        emit Unstaked(msg.sender, stakes[msg.sender][index]);
    }

    function getReward(uint256 index) external {
        require(
            index < stakes[msg.sender].length && index >= 0,
            "Index out of bounds"
        );
        uint256 rewards = calculateRewards(msg.sender, index);
        token.transfer(msg.sender, rewards);
        updatedTimes[msg.sender][index] = block.timestamp;

        emit RewardPaid(msg.sender, rewards);
    }

    function calculateRewards(
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        uint256 duration = block.timestamp.sub(updatedTimes[owner][index]);
        uint256 rewards = duration
            .mul(interestRate)
            .mul(stakes[owner][index])
            .div(100)
            .div(365 * 24 * 60 * 60);
        return rewards;
    }
}
