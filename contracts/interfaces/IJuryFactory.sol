pragma solidity ^0.8.9;

interface IJuryFactory {
    event JuryDepoyed(address indexed juryContract, uint96 swapInterval, uint8 jurySize);

    function deployJury(
        address[] memory _jurors,
        uint96 _swapInterval,
        uint8 _jurySize
    ) external returns (address);
}
