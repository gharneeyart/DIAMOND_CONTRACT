// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// We use structs for grouped data so that related fields travel together
// in storage and are easy to pass around in memory between library functions.

struct StakeInfo {
    address staker; // who locked the NFT
    uint256 stakedAt; // block.timestamp when staked — useful for future rewards
}

struct BorrowInfo {
    address lender; // owner who offered the borrow
    address borrower; // who is currently using the NFT
    uint256 borrowedAt; // when the borrow started
    uint256 duration; // how many seconds the borrower may hold it
    uint256 fee; // non-refundable amount paid to the lender
    uint256 collateral; // refundable only if the borrow is settled on time
}

struct Listing {
    address seller; // who put it up for sale
    uint256 price; // price denominated in the ERC20 token
    bool active; // false once sold or cancelled
}

// A multisig proposal represents one pending diamond upgrade.
// We cannot put a mapping inside a struct that is itself inside a mapping
// in some older patterns, but Solidity ≥0.8 handles it fine in AppStorage
// because AppStorage is accessed by reference (storage pointer), not copied.
struct Proposal {
    address proposer;
    address target; // address to call (usually the diamond itself)
    bytes callData; // the encoded diamondCut call
    uint256 approvals; // running count of approvals
    bool executed;
    mapping(address => bool) hasSigned;
}

struct AppStorage {
    string name;
    string symbol;
    uint256 currentTokenId;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    // ── ERC20 ─────────────────────────────────────────────────────────────────
    // Separate from NFT balances — same concept, different asset.
    string tokenName;
    string tokenSymbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) tokenBalances;
    mapping(address => mapping(address => uint256)) allowances;

    // ── Staking ───────────────────────────────────────────────────────────────
    mapping(uint256 => StakeInfo) stakes;
    // Lets us list all tokens a user has staked without iterating everything.
    mapping(address => uint256[]) stakedTokens;
    // Index inside stakedTokens[staker] so we can remove in O(1).
    mapping(address => mapping(uint256 => uint256)) stakedTokenIndex;

    // ── Borrowing ─────────────────────────────────────────────────────────────
    mapping(uint256 => BorrowInfo) borrows;

    // ── Marketplace ───────────────────────────────────────────────────────────
    mapping(uint256 => Listing) listings;

    // ── Multisig ──────────────────────────────────────────────────────────────
    mapping(address => bool) isSigner; // O(1) signer lookup
    address[] signers; // enumerable list for UI
    uint256 threshold; // how many approvals needed
    uint256 proposalCount;
    mapping(uint256 => Proposal) proposals;

    // ── SVG ───────────────────────────────────────────────────────────────────
    // Per-token SVG overrides let us update art without redeploying anything.
    mapping(uint256 => string) tokenSVGOverride;
}
