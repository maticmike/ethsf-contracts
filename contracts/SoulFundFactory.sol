// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IJuryFactory.sol";
import "./interfaces/ISoulFundFactory.sol";
import "./SoulFund.sol";

contract SoulFundFactory is ISoulFundFactory {
    address s_gasReceiver;
    address s_gateway;

    address s_data;

    IJuryFactory i_juryFactory;

    constructor(
        address _data,
        address _gateway,
        address _gasReceiver,
        address _juryFactory
    ) {
        s_data = _data;
        s_gasReceiver = _gasReceiver;
        s_gateway = _gateway;
        i_juryFactory = IJuryFactory(_juryFactory);
    }

    function deployNewSoulFund(
        uint256 _vestingDate,
        address[] calldata _trustees,
        uint96 _swapInterval,
        uint8 _jurySize
    ) external {
        require(
            _vestingDate > block.timestamp,
            "SoulFundFactory.deployNewSoulFund: vesting must be sometime in the future"
        );

        // not using this right now but we would pass this in to soulFund to allow it to have full access
        address jury = i_juryFactory.deployJury(_trustees, _swapInterval, _jurySize);

        SoulFund soulFund = new SoulFund(msg.sender, _vestingDate, s_data, s_gateway, s_gasReceiver);

        emit NewSoulFundTokenDeployed(address(soulFund), msg.sender, _vestingDate);
    }
}
