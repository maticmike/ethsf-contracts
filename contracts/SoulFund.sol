// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {AxelarExecutable} from "@axelar-network/axelar-utils-solidity/contracts/executables/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-utils-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";

import "./interfaces/ISoulFund.sol";
import "./interfaces/ITokenRenderer.sol";

contract SoulFund is ISoulFund, ERC721, AccessControl, AxelarExecutable {
    /*** CONSTANTS ***/
    bytes32 public constant GRANTER_ROLE = keccak256("GRANTER_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");

    uint256 public constant FIVE_PERCENT = 500;

    /*** STORAGE ***/
    string public sourceChain;
    string public sourceAddress;
    IAxelarGasService public immutable gasReceiver;
    IAxelarGateway immutable _gateway;
    uint256 private _tokenIdCounter;

    uint256 public vestingDate;

    //tokenId (soulfundId) => nftAddress => isWhitelisted
    mapping(uint256 => mapping(address => bool)) public whitelistedNfts;

    //tokenId (nftProofId) => nftAddress => isSpent
    mapping(uint256 => mapping(address => bool)) public nftIsSpent;

    //tokenId (soulfundId) => fundsRemaining
    //note: you can only have up to five different currencies
    mapping(uint256 => Balances[5]) public balances;

    //tokenId (soulfundId) => currency address => i where i -1 is the index in the balances array (1-based since 0 is null)
    mapping(uint256 => mapping(address => uint256)) public currencyIndices;

    //tokenId (soulfundId) => number of currencies in this fund right now
    //number of currencies in this soulfund NFT (max is five)
    mapping(uint256 => uint256) public numCurrencies;

    ITokenRenderer renderer;

    constructor(
        address _granter,
        uint256 _vestingDate,
        address _data,
        address gateway_,
        address gasReceiver_
    ) payable ERC721("SoulFund", "SLF") {
        // __ERC721_init("SoulFund", "SLF");

        _grantRole(DEFAULT_ADMIN_ROLE, _granter);
        _grantRole(GRANTER_ROLE, _granter);

        vestingDate = _vestingDate;
        renderer = ITokenRenderer(_data);

        gasReceiver = IAxelarGasService(gasReceiver_);
        _gateway = IAxelarGateway(gateway_);
    }

    function depositFund(
        uint256 soulFundId,
        address currency,
        uint256 amount
    ) external payable override onlyRole(GRANTER_ROLE) {
        // require that currency exists or max has not been reached
        require(
            currencyIndices[soulFundId][currency] >= 0 &&
                numCurrencies[soulFundId] < 5,
            "SoulFund.depositFund: max currency type reached."
        );

        uint256 index = currencyIndices[soulFundId][currency];

        // add currency if needed
        if (index == 0) {
            // increment numCurrencies
            numCurrencies[soulFundId]++;
            // set currency indices
            currencyIndices[soulFundId][currency] = numCurrencies[soulFundId];
            // add currency
            index = currencyIndices[soulFundId][currency];
            balances[soulFundId][index].token = currency;
        }

        // add fund
        if (currency == address(0)) {
            // treat as eth
            require(
                msg.value == amount,
                "SoulFund.depositFund: amount mismatch."
            );
        } else {
            // treat as erc20
            IERC20(currency).transferFrom(msg.sender, address(this), amount);
        }
        balances[soulFundId][index].balance += amount;

        emit FundDeposited(soulFundId, currency, amount, ownerOf(soulFundId));
    }

    function safeMint(address _to) external onlyRole(GRANTER_ROLE) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _grantRole(BENEFICIARY_ROLE, _to);
        _safeMint(_to, tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        require(
            _from == address(0),
            "SoulFund: soul bound token cannot be transferred"
        );
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function gateway() public view override returns (IAxelarGateway) {
        return _gateway;
    }

    // function whitelistNft(address _newNftAddress, uint256 _tokenId)
    //     external
    //     override
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     require(
    //         whitelistedNfts[_tokenId][_newNftAddress] == false,
    //         "SoulFund.whitelistNft: address already added"
    //     );
    //     require(
    //         _newNftAddress != address(0),
    //         "SoulFund.whitelistNft: cannot add 0 address"
    //     );

    //     whitelistedNfts[_tokenId][_newNftAddress] = true;

    //     emit NewWhitelistedNFT(_newNftAddress);
    // }

    //Claim 5% of funds in contract with claimToken (nft)
    function _claimFundsEarly(uint256 _soulFundId, address _holder) internal {
        address beneficiary = ownerOf(_soulFundId);
        require(
            _holder == beneficiary,
            "SoulFund.claimFundsEarly: invalid address"
        );

        // require(
        //     IERC721(_nftAddress).ownerOf(_nftId) == beneficiary,
        //     "SoulFund.claimFundsEarly: beneficiary does not own nft required to claim funds"
        // );
        // require(
        //     ownerOf(_soulFundId) != address(0),
        //     "SoulFund.claimFundsEarly: fund does not exist"
        // );
        // require(
        //     !nftIsSpent[_nftId][_nftAddress],
        //     "SoulFund.claimFundsEarly: Claim token NFT has already been spent"
        // );

        _transferAllFunds(_soulFundId, FIVE_PERCENT);

        // TODO replace dummy aggregatedAmount with computed aggregation result
        uint256 aggregatedAmount = 1;

        //spend nft
        // nftIsSpent[_nftId][_nftAddress] = true;

        payable(beneficiary).transfer(aggregatedAmount);

        emit VestedFundsClaimedEarly(_soulFundId, aggregatedAmount);
    }

    function claimAllVestedFunds(uint256 _soulFundId)
        external
        payable
        override
    {
        require(
            ownerOf(_soulFundId) != address(0),
            "SoulFund.claimFundsEarly: fund does not exist"
        );

        _transferAllFunds(_soulFundId, 1);

        // TODO replace dummy aggregatedAmount with computed aggregation result
        uint256 aggregatedAmount = 1;

        emit VestedFundClaimed(_soulFundId, aggregatedAmount);
    }

    function _transferAllFunds(uint256 _soulFundId, uint256 percentage)
        internal
    {
        // loop through all currencies
        require(percentage <= 10000, "Percent too high");
        for (uint256 i = 0; i < numCurrencies[_soulFundId]; i++) {
            address currency = balances[_soulFundId][i].token;
            uint256 amount = (balances[_soulFundId][i].balance * percentage) /
                10000;

            // mutex may be necessary (claimAllVested && claimFundsEarly)
            balances[_soulFundId][i].balance -= amount;
            if (currency == address(0)) {
                // eth
                payable(ownerOf(_soulFundId)).transfer(amount);
            } else {
                // erc20
                IERC20(currency).transfer(ownerOf(_soulFundId), amount);
            }
        }
    }

    function balancesExt(uint256 _tokenId)
        external
        view
        returns (Balances[5] memory)
    {
        return balances[_tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return renderer.renderToken(address(this), tokenId);
    }

    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (address holder, uint256 soulFundId) = abi.decode(
            payload_,
            (address, uint256)
        );
        sourceChain = sourceChain_;
        sourceAddress = sourceAddress_;

        _claimFundsEarly(soulFundId, holder);
    }
}
