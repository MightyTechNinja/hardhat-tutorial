//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

contract NinjaToken is IERC20 {
    string public name = "Ninja Token";
    string public symbol = "NTN";
    uint256 public totalSupply = 1000000;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        balances[to] = balances[to] + value;
        emit Transfer(from, to, value);
        return true;
    }
}
