// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/ISoulFundFactory.sol";
import "./SoulFund.sol";

contract SoulFundFactory is ISoulFundFactory {
    address s_gasReceiver;
    address s_gateway;

    address s_data;

    constructor(
        address _data,
        address _gateway,
        address _gasReceiver
    ) {
        s_data = _data;
        s_gasReceiver = _gasReceiver;
        s_gateway = _gateway;
    }

    function deployNewSoulFund(uint256 _vestingDate) external {
        require(
            _vestingDate > block.timestamp,
            "SoulFundFactory.deployNewSoulFund: vesting must be sometime in the future"
        );

        SoulFund soulFund = new SoulFund(msg.sender, _vestingDate, s_data, s_gateway, s_gasReceiver);

        emit NewSoulFundTokenDeployed(address(soulFund), msg.sender, _vestingDate);
    }
}
