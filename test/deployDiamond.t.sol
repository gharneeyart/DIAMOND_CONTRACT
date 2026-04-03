// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "../contracts/Diamond.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract DiamondDeploy is DiamondUpgradeHelper {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    ERC721Facet nft;

    address ganiyat;
    address feyi;
    address tobi;

    function setUp() public {
        ganiyat = makeAddr("ganiyat");
        feyi = makeAddr("feyi");
        tobi = makeAddr("tobi");

        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        nft = new ERC721Facet();

        address[] memory addrs = new address[](3);
        addrs[0] = address(dLoupe);
        addrs[1] = address(ownerF);
        addrs[2] = address(nft);

        string[] memory names = new string[](3);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        names[2] = "ERC721Facet";

        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        nft = ERC721Facet(address(diamond));
        nft.init("OnChain", "OC");
    }

    function testDeployStoresNameAndSymbol() public {
        assertEq(nft.name(), "OnChain");
        assertEq(nft.symbol(), "OC");
    }

    function testMintSetsOwnerAndBalance() public {
        nft.mint(ganiyat);
        assertEq(nft.ownerOf(0), ganiyat);
        assertEq(nft.balanceOf(ganiyat), 1);
    }

    function testApproveAndApprovedTransferWorks() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        nft.approve(feyi, 0);
        vm.prank(feyi);
        nft.transferFrom(ganiyat, tobi, 0);
        assertEq(nft.ownerOf(0), tobi);
        assertEq(nft.balanceOf(tobi), 1);
    }

    function testSetApprovalForAllAllowsTransfer() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        nft.setApprovalForAll(feyi, true);
        vm.prank(feyi);
        nft.transferFrom(ganiyat, tobi, 0);
        assertEq(nft.ownerOf(0), tobi);
    }
}

