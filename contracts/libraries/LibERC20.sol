// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage} from "../storage/AppStorage.sol";

// LibERC20 holds the raw token movement logic so MarketplaceFacet can
// call it directly without going through the external ERC20Facet interface
// (which would be a self-call through the proxy — more gas, more complexity).
library LibERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Move tokens between accounts after verifying balance.
    // Called by ERC20Facet.transfer and by MarketplaceFacet when a sale settles.
    function transfer(AppStorage storage s, address from, address to, uint256 amount) internal {
        require(to != address(0), "Zero address");
        require(s.tokenBalances[from] >= amount, "Insufficient balance");
        s.tokenBalances[from] -= amount;
        s.tokenBalances[to] += amount;
        emit Transfer(from, to, amount);
    }

    // Spend an allowance and then move tokens.
    // Used by MarketplaceFacet: buyer pre-approves marketplace, marketplace calls this.
    function transferFrom(AppStorage storage s, address spender, address from, address to, uint256 amount) internal {
        require(s.allowances[from][spender] >= amount, "Allowance too low");
        s.allowances[from][spender] -= amount;
        transfer(s, from, to, amount);
    }
}
