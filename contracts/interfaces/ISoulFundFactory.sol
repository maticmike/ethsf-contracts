// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISoulFundFactory {
    event NewSoulFundTokenDeployed(
        address indexed tokenAddress,
        address indexed beneficiary,
        uint256 vestingDate,
        uint256 depositedAmount
    );

    function deployNewSoulFund(
        address _beneficiary,
        uint256 _vestingDate
        // uint256 _depositAmount  FOR ERC20s <<<<<<
    ) external payable;
}
