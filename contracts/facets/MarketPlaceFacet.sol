// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage, Listing} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibNFT} from "../libraries/LibNFT.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

// Peer-to-peer NFT marketplace using the ERC20 token as currency.
// The flow: seller lists → buyer approves ERC20 spend → buyer calls buy.
// No ETH involved — everything settles in the protocol token.
contract MarketplaceFacet {
    event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event Cancelled(uint256 indexed tokenId);
    event Sold(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    // Seller creates a listing.  NFT stays in their wallet until sold.
    function list(uint256 tokenId, uint256 price) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.owners[tokenId] == msg.sender, "Not owner");
        require(price > 0, "Zero price");

        // Cannot list a staked or borrowed token.
        LibNFT.requireNotStaked(s, tokenId);
        LibNFT.requireNotBorrowed(s, tokenId);

        s.listings[tokenId] = Listing({seller: msg.sender, price: price, active: true});

        emit Listed(msg.sender, tokenId, price);
    }

    // Seller removes their listing.
    function cancelListing(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.listings[tokenId].seller == msg.sender, "Not seller");
        require(s.listings[tokenId].active, "Not active");

        delete s.listings[tokenId];
        emit Cancelled(tokenId);
    }

    // Buyer purchases. They must have pre-approved the diamond to spend `price` tokens.
    function buy(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        Listing memory listing = s.listings[tokenId];
        require(listing.active, "Not listed");
        require(msg.sender != listing.seller, "Seller cannot buy own NFT");

        // Mark inactive BEFORE any transfers — prevents reentrancy.
        delete s.listings[tokenId];

        // Move the ERC20 payment from buyer to seller.
        // address(this) is the diamond proxy, which is the approved spender.
        LibERC20.transferFrom(s, address(this), msg.sender, listing.seller, listing.price);

        // Move the NFT from seller to buyer.
        LibNFT.transfer(s, listing.seller, msg.sender, tokenId);

        emit Sold(listing.seller, msg.sender, tokenId, listing.price);
    }

    function getListing(uint256 tokenId) external view returns (Listing memory) {
        return LibAppStorage.diamondStorage().listings[tokenId];
    }
}
