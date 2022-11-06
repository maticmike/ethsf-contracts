// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISoulFundFactory {
    event NewSoulFundTokenDeployed(address indexed tokenAddress, address indexed granter, uint256 vestingDate);

    function deployNewSoulFund(uint256 _vestingDate) external;
}
