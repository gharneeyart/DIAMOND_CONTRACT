// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage, StakeInfo} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibNFT} from "../libraries/LibNFT.sol";

contract StakingFacet {
    event Staked(address indexed staker, uint256 indexed tokenId);
    event Unstaked(address indexed staker, uint256 indexed tokenId);

    // Caller locks their NFT into the diamond.
    // The NFT transfers to address(this) (the diamond proxy).
    // We record the original owner so they can unstake later.
    function stake(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Only the owner can stake.
        require(s.owners[tokenId] == msg.sender, "Not owner");

        // Token must be free — not borrowed or listed.
        LibNFT.requireNotBorrowed(s, tokenId);
        LibNFT.requireNotListed(s, tokenId);

        // Record stake info BEFORE the transfer so reentrancy can't double-stake.
        s.stakes[tokenId] = StakeInfo({staker: msg.sender, stakedAt: block.timestamp});

        // Track the index so we can remove it in O(1) on unstake.
        uint256 idx = s.stakedTokens[msg.sender].length;
        s.stakedTokens[msg.sender].push(tokenId);
        s.stakedTokenIndex[msg.sender][tokenId] = idx;

        // Transfer ownership to the diamond itself.
        LibNFT.transfer(s, msg.sender, address(this), tokenId);

        emit Staked(msg.sender, tokenId);
    }

    // Caller reclaims their NFT.
    function unstake(uint256 tokenId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        StakeInfo memory info = s.stakes[tokenId];
        require(info.staker == msg.sender, "Not staker");

        // Clear stake record BEFORE transferring (reentrancy guard pattern).
        delete s.stakes[tokenId];
        _removeFromStakedList(s, msg.sender, tokenId);

        // Transfer back to the original staker.
        LibNFT.transfer(s, address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, tokenId);
    }

    // View helper — returns all token IDs currently staked by an address.
    function stakedTokensOf(address staker) external view returns (uint256[] memory) {
        return LibAppStorage.diamondStorage().stakedTokens[staker];
    }

    // O(1) removal by swap-and-pop.
    // We swap the target element with the last one, update its index, then pop.
    function _removeFromStakedList(AppStorage storage s, address staker, uint256 tokenId) private {
        uint256 idx = s.stakedTokenIndex[staker][tokenId];
        uint256 last = s.stakedTokens[staker].length - 1;

        if (idx != last) {
            uint256 lastToken = s.stakedTokens[staker][last];
            s.stakedTokens[staker][idx] = lastToken;
            s.stakedTokenIndex[staker][lastToken] = idx;
        }

        s.stakedTokens[staker].pop();
        delete s.stakedTokenIndex[staker][tokenId];
    }
}
