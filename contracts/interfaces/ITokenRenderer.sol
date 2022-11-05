// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITokenRenderer {
    function renderToken(address _soulfund, uint256 _tokenId)
        external
        view
        returns (string memory);
}
