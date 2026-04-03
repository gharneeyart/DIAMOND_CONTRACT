// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage} from "../storage/AppStorage.sol";

// LibNFT centralises every guard that multiple facets need to check.
// Rather than duplicating "is this token staked?" in StakingFacet AND
// MarketplaceFacet, we put it here once and call it from both.
library LibNFT {
    // Reverts if the token is currently locked in the staking contract.
    // Staked tokens cannot be transferred, listed, or borrowed.
    function requireNotStaked(AppStorage storage s, uint256 tokenId) internal view {
        require(s.stakes[tokenId].staker == address(0), "Token is staked");
    }

    // Reverts if the token has a live borrow offer or an active borrower.
    // This keeps one token from being listed, staked, transferred, and borrowed
    // under different assumptions at the same time.
    function requireNotBorrowed(AppStorage storage s, uint256 tokenId) internal view {
        require(s.borrows[tokenId].lender == address(0), "Token has borrow record");
    }

    // Reverts if there is an active marketplace listing.
    // Listed tokens cannot be staked or borrowed until the listing is cancelled.
    function requireNotListed(AppStorage storage s, uint256 tokenId) internal view {
        require(!s.listings[tokenId].active, "Token is listed");
    }

    // Convenience: all three checks at once for transfer operations.
    function requireFree(AppStorage storage s, uint256 tokenId) internal view {
        requireNotStaked(s, tokenId);
        requireNotBorrowed(s, tokenId);
        requireNotListed(s, tokenId);
    }

    // Internal transfer with no approval check — used by facets that have
    // already verified authorisation (staking, marketplace, etc.).
    function transfer(AppStorage storage s, address from, address to, uint256 tokenId) internal {
        require(to != address(0), "Zero address");
        require(s.owners[tokenId] == from, "Wrong owner");
        s.balances[from] -= 1;
        s.balances[to] += 1;
        s.owners[tokenId] = to;
        delete s.tokenApprovals[tokenId]; // clear single-token approval on move
        emit Transfer(from, to, tokenId);
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
