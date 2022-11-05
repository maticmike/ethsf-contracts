// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ISoulFund.sol";
import "./libraries/SoulFundLibrary.sol";

contract TokenRenderer is UUPSUpgradeable, OwnableUpgradeable {
    struct Attributes {
        string name;
        string color;
        address aggregator;
    }

    mapping(address => Attributes) tokenToAttributes;

    // populate with token names, colors, values
    function initialize(
        address[] memory _addresses,
        string[] memory _names,
        string[] memory _colors,
        address[] memory _aggregators
    ) public initializer {
        require(
            _addresses.length == _names.length &&
                _names.length == _colors.length &&
                _colors.length == _aggregators.length,
            "Invalid param length"
        );
        for (uint8 i = 0; i < _addresses.length; i++) {
            tokenToAttributes[_addresses[i]] = Attributes({
                name: _names[i],
                color: _colors[i],
                aggregator: _aggregators[i]
            });
        }
    }

    // generate svg
    // will work more on svg display in am
    function _svg(
        ISoulFund.Balances[5] memory _balances,
        uint256 _totalUSD,
        uint256[] memory _percentages,
        uint256 vestedDate
    ) internal view returns (string memory) {
        string memory svg;
        string memory pie;
        string memory color;
        string memory name;
        uint256 percentage = 1;

        for (uint256 i = 0; i < _percentages.length; i++) {
            name = tokenToAttributes[_balances[i].token].name;
            color = tokenToAttributes[_balances[i].token].color;
            percentage += _percentages[i];

            if (_balances[i].balance > 0) {
                // fill in labels
                svg = string(
                    abi.encodePacked(
                        svg,
                        '<svg width="8px" height="5px" x="',
                        SoulFundLibrary.toString(8 * i),
                        '" y="30">',
                        '<rect style="fill:',
                        color,
                        '" x="20%" y="4" />',
                        '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size:2px;fill: #000;">',
                        name,
                        "</text></svg>"
                    )
                );
            }

            // fill in pie chart
            pie = string(
                abi.encodePacked(
                    '<circle r="5" cx="10" cy="10" fill="transparent" stroke="',
                    color,
                    '" stroke-width="10" stroke-dasharray="calc(',
                    SoulFundLibrary.toString(percentage),
                    ' * 31.4 / 100) 31.4"'
                    ' transform="rotate(-90) translate(-20)" />',
                    pie
                )
            );
        }

        // put it all together
        svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="main" viewBox="0 0 40 40" preserveAspectRatio="xMinYMin meet" shape-rendering="crisp-edges">',
                '<svg width="40px" height="5px" x="0" y="3">',
                '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size:3px;fill: #000;">$',
                SoulFundLibrary.getDecimalString(_totalUSD),
                "</text></svg>",
                '<svg id="pie" x="10" y="10" height="20" width="20" viewBox="0 0 20 20">',
                '<circle r="10" cx="10" cy="10" fill="white" />',
                pie,
                "</svg>",
                svg,
                '<svg width="40px" height="5px" x="0" y="36">',
                '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" style="font-size:2px;fill: #000;">',
                SoulFundLibrary.toString(vestedDate),
                " Minutes Until Next Vest",
                "</text></svg>",
                "<style>text{font-family:Arial;}rect{width:5px;height:1px;}</style></svg>"
            )
        );

        // base64 encode
        return SoulFundLibrary.encode(bytes(svg));
    }

    // generate metadata
    function _meta(ISoulFund.Balances[5] memory _balances)
        internal
        view
        returns (
            string memory,
            uint256,
            uint256[] memory
        )
    {
        uint256 totalUSD;
        uint256[] memory usdValues = new uint256[](_balances.length);
        uint256[] memory percentages = new uint256[](_balances.length);
        string memory metadataString;

        // get USD value of tokens, create total $USD using chainlink aggregator
        for (uint256 i = 0; i < _balances.length; i++) {
            usdValues[i] =
                (_getPrice(tokenToAttributes[_balances[i].token].aggregator) *
                    _balances[i].balance) /
                1 ether;
            totalUSD +=
                (_getPrice(tokenToAttributes[_balances[i].token].aggregator) *
                    _balances[i].balance) /
                1 ether;
        }

        // populate metadata with individual token holdings in $USD
        for (uint256 i = 0; i < usdValues.length; i++) {
            percentages[i] = SoulFundLibrary.getPercent(usdValues[i], totalUSD);
            if (_balances[i].balance > 0) {
                metadataString = string(
                    abi.encodePacked(
                        metadataString,
                        '{"trait_type":"',
                        tokenToAttributes[_balances[i].token].name,
                        '","value":"$',
                        SoulFundLibrary.getDecimalString(usdValues[i]),
                        '"},'
                    )
                );
            }
        }

        // populate metadata with Total $USD
        metadataString = string(
            abi.encodePacked(
                metadataString,
                '{"trait_type":"Total Value","value":"$',
                SoulFundLibrary.getDecimalString(totalUSD),
                '"}'
            )
        );

        // return the percentages calculated and total values
        return (metadataString, totalUSD, percentages);
    }

    // chainlink aggregator
    function _getPrice(address _aggregator) internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 v, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = AggregatorV3Interface(_aggregator).latestRoundData();
        return uint256(v) * 10**10;
    }

    // render token function called by TokenURI
    function renderToken(address _soulfund, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        ISoulFund.Balances[5] memory balances = ISoulFund(_soulfund)
            .balancesExt(_tokenId);
        string memory metadata;
        uint256 totalUSD;
        uint256[] memory percentages;

        uint256 vestedDate = ISoulFund(_soulfund).vestingDate();
        if (block.timestamp >= vestedDate) {
            vestedDate = 0;
        } else {
            vestedDate = (vestedDate - block.timestamp) / 60;
        }

        // pull metadata as well metadata used for svg generation
        (metadata, totalUSD, percentages) = _meta(balances);

        // generate svg
        string memory svg = _svg(balances, totalUSD, percentages, vestedDate);

        // return a base64 encoded json to render
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    SoulFundLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "SoulFund #',
                                    SoulFundLibrary.toString(_tokenId),
                                    '",',
                                    '"description": "SoulFund is a Soulbound Time & Merit Based Funding Token.",',
                                    '"image": "data:image/svg+xml;base64,',
                                    svg,
                                    '","attributes": [',
                                    metadata,
                                    "]}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
