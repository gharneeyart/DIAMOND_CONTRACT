// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage, BorrowInfo} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {LibNFT} from "../libraries/LibNFT.sol";

// Borrowing gives someone temporary *usage rights* without transferring ownership.
// The NFT stays with the owner; the borrower is recorded in storage.
// Facets that gate on ownership will still see the real owner.
// Facets that care about usage (e.g., a game) should check borrows[tokenId].borrower.
contract BorrowerFacet {
    event BorrowOfferCreated(
        address indexed lender, uint256 indexed tokenId, uint256 duration, uint256 fee, uint256 collateral
    );
    event BorrowOfferCancelled(uint256 indexed tokenId);
    event Borrowed(address indexed borrower, uint256 indexed tokenId, uint256 duration, uint256 collateral);
    event Returned(uint256 indexed tokenId, bool collateralForfeited);

    // Owner creates an open borrow offer.
    // Anyone can accept it, but they must pay the fee and lock collateral first.
    function lend(uint256 tokenId, uint256 duration, uint256 fee, uint256 collateral) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.owners[tokenId] == msg.sender, "Not owner");
        require(duration > 0, "Zero duration");

        // Cannot lend a staked or listed token.
        LibNFT.requireNotStaked(s, tokenId);
        LibNFT.requireNotListed(s, tokenId);
        require(s.borrows[tokenId].lender == address(0), "Borrow already configured");

        s.borrows[tokenId] = BorrowInfo({
            lender: msg.sender,
            borrower: address(0),
            borrowedAt: 0,
            duration: duration,
            fee: fee,
            collateral: collateral
        });

        emit BorrowOfferCreated(msg.sender, tokenId, duration, fee, collateral);
    }

    // Owner can cancel before anyone accepts the offer.
    function cancelLend(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowInfo memory info = s.borrows[tokenId];

        require(info.lender == msg.sender, "Not lender");
        require(info.borrower == address(0), "Already borrowed");

        delete s.borrows[tokenId];
        emit BorrowOfferCancelled(tokenId);
    }

    // Borrower pays the lender's fee and locks collateral inside the diamond.
    function borrow(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowInfo storage info = s.borrows[tokenId];

        require(info.lender != address(0), "Not lendable");
        require(info.borrower == address(0), "Already borrowed");
        require(msg.sender != info.lender, "Lender cannot borrow");

        if (info.fee > 0) {
            LibERC20.transferFrom(s, address(this), msg.sender, info.lender, info.fee);
        }
        if (info.collateral > 0) {
            LibERC20.transferFrom(s, address(this), msg.sender, address(this), info.collateral);
        }

        info.borrower = msg.sender;
        info.borrowedAt = block.timestamp;

        emit Borrowed(msg.sender, tokenId, info.duration, info.collateral);
    }

    // Before expiry, collateral goes back to the borrower.
    // After expiry, collateral is forfeited to the lender.
    function returnNFT(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowInfo memory info = s.borrows[tokenId];

        require(info.borrower != address(0), "Not borrowed");

        bool expired = block.timestamp >= info.borrowedAt + info.duration;
        bool authorised = msg.sender == info.borrower || msg.sender == info.lender || expired;
        require(authorised, "Not authorised");

        if (info.collateral > 0) {
            address recipient = expired ? info.lender : info.borrower;
            LibERC20.transfer(s, address(this), recipient, info.collateral);
        }

        delete s.borrows[tokenId];
        emit Returned(tokenId, expired);
    }

    function borrowInfo(uint256 tokenId) external view returns (BorrowInfo memory) {
        return LibAppStorage.diamondStorage().borrows[tokenId];
    }

    // True if the token is currently out on loan AND the duration hasn't elapsed.
    function isActiveBorrow(uint256 tokenId) external view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        BorrowInfo memory info = s.borrows[tokenId];
        if (info.borrower == address(0)) return false;
        return block.timestamp < info.borrowedAt + info.duration;
    }
}
