//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";
import "./NftRoyalty.sol";

/// NFT Trader Contract for buying/selling NFTRoyalty Token
/// @author hosokawa-zen
contract NftTrader {

    /// NFT Trade Structure
    struct Trade {
        uint256 price;
        address seller;
    }

    /// Trade map : Mapping of contract Address => tokenId => Trade
    mapping(address => mapping(uint256 => Trade)) public trades;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public royaltyBalances;

    /// Percent Division
    uint16 internal constant PERCENT_DIVISOR = 10 ** 4;

    /// Events
    event AddTrade(uint256 price, address indexed contractAddr, uint256 tokenId);
    event Purchase(address indexed contractAddr, uint256 tokenId, uint256 price);
    event Withdraw(address indexed destAddr, uint256 amount);
    event ClaimRoyalty(address indexed destAddr, uint256 amount);


    /// Add Trade
    /// @param price NFT Token Price
    /// @param contractAddr NFT Contract Address
    /// @param tokenId NFT Token ID
    function addTrade(uint256 price, address contractAddr, uint256 tokenId) external {
        IERC721 token = IERC721(contractAddr);

        require(token.ownerOf(tokenId) == msg.sender, "NftTrader: caller is not owner");
        require(token.isApprovedForAll(msg.sender, address(this)), "NftTrader: contract must be approved");

        trades[contractAddr][tokenId] = Trade({
            price: price,
            seller: msg.sender
        });

        emit AddTrade(price, contractAddr, tokenId);
    }

    /// Purchase NftRoyalty Token
    /// @param contractAddr NFT Contract Address
    /// @param tokenId NFT Token ID
    function purchase(address contractAddr, uint256 tokenId) external payable {
        Trade memory item = trades[contractAddr][tokenId];
        require(msg.value >= item.price, "NftTrader: Insufficient funds");

        // Get NftRoyalty Token Data
        NftRoyalty token = NftRoyalty(contractAddr);
        (uint256 artistRoyalty, address artistAddr, uint256 charityRoyalty, address charityAddr) = token.getRoyaltyData(tokenId);

        // Calculate Royalty for artist and charity
        uint256 artistRoyalAmt = (artistRoyalty * msg.value)/PERCENT_DIVISOR;
        uint256 charityRoyalAmt = (charityRoyalty * msg.value)/PERCENT_DIVISOR;

        // Update Balances
        royaltyBalances[artistAddr] += artistRoyalAmt;
        royaltyBalances[charityAddr] += charityRoyalAmt;
        balances[item.seller] += msg.value - artistRoyalAmt - charityRoyalAmt;

        emit Purchase(contractAddr, tokenId, item.price);
    }

    /// Withdraw about Token Sell Trade
    function withdraw(address payable destAddr) public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No Funds");

        destAddr.transfer(amount);
        balances[msg.sender] = 0;

        emit Withdraw(destAddr, amount);
    }

    /// Withdraw Royalty about Token Trade
    function claimRoyalty(address payable destAddr) public {
        uint256 amount = royaltyBalances[msg.sender];
        require(amount > 0, "No Funds");

        destAddr.transfer(amount);
        royaltyBalances[msg.sender] = 0;

        emit ClaimRoyalty(destAddr, amount);
    }
}
