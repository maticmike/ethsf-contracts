// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IJuryFactory.sol";
import "./Jury.sol";

contract JuryFactory is IJuryFactory {
    constructor() {}

    function deployJury(
        address[] calldata _jurors,
        uint96 _swapInterval,
        uint8 _jurySize
    ) external returns (address) {
        Jury jury = new Jury(_jurors, _swapInterval, _jurySize);
        emit JuryDepoyed(address(jury), _swapInterval, _jurySize);
        return address(jury);
    }
}
