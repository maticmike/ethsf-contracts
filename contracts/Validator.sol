// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import {IAxelarGateway} from "@axelar-network/axelar-utils-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract Validator {
    IAxelarGasService public immutable gasReceiver;
    IAxelarGateway immutable _gateway;
    address beneficiary;

    event NewWhitelistedNFT(address newNftAddress);

    // nftAddress => isWhitelisted
    mapping(address => bool) public whitelistedNfts;

    // nftAddress => isSpent
    mapping(address => bool) public nftIsSpent;

    constructor(address gateway_, address gasReceiver_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        _gateway = IAxelarGateway(gateway_);
    }

    function gateway() public view returns (IAxelarGateway) {
        return _gateway;
    }

    // Call this function to update the value of this contract along with all its siblings'.
    function validateAndClaim(
        string calldata destinationChain,
        string calldata destinationAddress,
        address _nftAddress,
        uint256 _nftId,
        uint256 _souldFundId
    ) external payable {
        address holder = _validate(_nftAddress, _nftId);

        bytes memory payload = abi.encode(holder, _souldFundId);
        if (msg.value > 0) {
            gasReceiver.payNativeGasForContractCall{value: msg.value}(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }
        gateway().callContract(destinationChain, destinationAddress, payload);
    }

    function whitelistNft(address _newNftAddress) external {
        require(whitelistedNfts[_newNftAddress] == false, "validator.whitelistNft: address already added");
        require(_newNftAddress != address(0), "validator.whitelistNft: cannot add 0 address");

        whitelistedNfts[_newNftAddress] = true;

        emit NewWhitelistedNFT(_newNftAddress);
    }

    function _validate(address _nftAddress, uint256 _nftId) internal returns (address) {
        require(whitelistedNfts[_nftAddress], "SoulFund.claimFundsEarly: NFT not whitelisted");

        require(!nftIsSpent[_nftAddress], "SoulFund.claimFundsEarly: Claim token NFT has already been spent");

        return IERC721Upgradeable(_nftAddress).ownerOf(_nftId);
    }
}
