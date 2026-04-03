// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

contract ERC20Facet {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initERC20(string memory _name, string memory _symbol, uint8 _decimals) external {
        LibAppStorage.enforceOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(bytes(s.tokenName).length == 0, "Already initialised");
        s.tokenName = _name;
        s.tokenSymbol = _symbol;
        s.decimals = _decimals;
    }

    function tokenName() external view returns (string memory) {
        return LibAppStorage.diamondStorage().tokenName;
    }

    function tokenSymbol() external view returns (string memory) {
        return LibAppStorage.diamondStorage().tokenSymbol;
    }

    function decimals() external view returns (uint8) {
        return LibAppStorage.diamondStorage().decimals;
    }

    function totalSupply() external view returns (uint256) {
        return LibAppStorage.diamondStorage().totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return LibAppStorage.diamondStorage().tokenBalances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return LibAppStorage.diamondStorage().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        LibERC20.transfer(LibAppStorage.diamondStorage(), msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        LibERC20.transferFrom(LibAppStorage.diamondStorage(), msg.sender, from, to, amount);
        return true;
    }

    // Mint is operational — owner only, not multisig gated.
    function mint(address to, uint256 amount) external {
        LibAppStorage.enforceOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(to != address(0), "Zero address");
        s.tokenBalances[to] += amount;
        s.totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.tokenBalances[msg.sender] >= amount, "Insufficient balance");
        s.tokenBalances[msg.sender] -= amount;
        s.totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
