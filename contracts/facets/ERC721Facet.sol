// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// ERC-721 facet for Diamond implementation
// App storage contains ERC-721 state variables and is shared across facets
import {AppStorage} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibNFT} from "../libraries/LibNFT.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {Base64} from "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract ERC721Facet is IERC721 {
    AppStorage internal s;
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function init(string memory _name, string memory _symbol) external {
        LibAppStorage.enforceMultisig();
        require(bytes(s.name).length == 0, "Already initialized");
        require(bytes(s.symbol).length == 0, "Already initialized");
        s.name = _name;
        s.symbol = _symbol;
    }

    function name() external view returns (string memory) {
        return s.name;
    }

    function symbol() external view returns (string memory) {
        return s.symbol;
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "!ZA");
        return s.balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = s.owners[_tokenId];
        require(owner != address(0), "Invalid token ID");
        return owner;
    }

    function approve(address _to, uint256 _tokenId) external override {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || s.operatorApprovals[owner][msg.sender], "caller is not owner nor operator");
        s.tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view override returns (address) {
        require(s.owners[_tokenId] != address(0), "Invalid token ID");
        return s.tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        s.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return s.operatorApprovals[_owner][_operator];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = s.owners[tokenId];
        return (spender == owner || s.tokenApprovals[tokenId] == spender || s.operatorApprovals[owner][spender]);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        require(ownerOf(tokenId) == from, "Wrong owner");
        LibNFT.requireFree(s, tokenId);
        LibNFT.transfer(s, from, to, tokenId);
    }

    function mint(address _to) external {
        LibAppStorage.enforceOwner();
        require(_to != address(0), "!ZA");
        uint256 tokenId = s.currentTokenId++;
        s.owners[tokenId] = _to;
        s.balances[_to] += 1;
        emit Transfer(address(0), _to, tokenId);
    }
}
