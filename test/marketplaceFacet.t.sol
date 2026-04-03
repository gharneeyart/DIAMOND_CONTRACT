// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "../contracts/Diamond.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "./helpers/DiamondUpgradeHelper.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/MarketplaceFacet.sol";

contract MarketplaceTest is DiamondUpgradeHelper {
    Diamond diamond;
    ERC721Facet nft;
    ERC20Facet erc20;
    MarketplaceFacet market;
    address ganiyat;
    address feyi;

    function setUp() public {
        ganiyat = makeAddr("ganiyat");
        feyi = makeAddr("feyi");

        DiamondCutFacet dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));

        // Phase 1 — Loupe + Ownership + ERC20
        address[] memory addrs1 = new address[](3);
        addrs1[0] = address(new DiamondLoupeFacet());
        addrs1[1] = address(new OwnershipFacet());
        addrs1[2] = address(new ERC20Facet());

        string[] memory names1 = new string[](3);
        names1[0] = "DiamondLoupeFacet";
        names1[1] = "OwnershipFacet";
        names1[2] = "ERC20Facet";

        executeDiamondCut(IDiamondCut(address(diamond)), buildAddCutsByNames(addrs1, names1), address(0), "");

        // Phase 2 — ERC721 (non-colliding) + Marketplace
        IDiamondCut.FacetCut[] memory cuts2 = new IDiamondCut.FacetCut[](2);
        cuts2[0] = buildAddMissingCutByName(IDiamondLoupe(address(diamond)), address(new ERC721Facet()), "ERC721Facet");
        cuts2[1] = buildAddCutByName(address(new MarketplaceFacet()), "MarketplaceFacet");
        executeDiamondCut(IDiamondCut(address(diamond)), cuts2, address(0), "");

        nft = ERC721Facet(address(diamond));
        nft.init("OnChain", "OC");
        erc20 = ERC20Facet(address(diamond));
        erc20.initERC20("TestToken", "TT", 18);
        market = MarketplaceFacet(address(diamond));
    }

    function testListCreatesActiveListing() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        market.list(0, 100e18);

        Listing memory l = market.getListing(0);
        assertEq(l.seller, ganiyat);
        assertEq(l.price, 100e18);
        assertTrue(l.active);
    }

    function testCancelListingDeactivates() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        market.list(0, 100e18);
        vm.prank(ganiyat);
        market.cancelListing(0);

        Listing memory l = market.getListing(0);
        assertFalse(l.active);
    }

    function testBuyTransfersNFTAndTokens() public {
        nft.mint(ganiyat); // token 0
        vm.prank(ganiyat);
        market.list(0, 100e18);

        erc20.mint(feyi, 100e18);
        vm.startPrank(feyi);
        erc20.approve(address(diamond), 100e18);
        market.buy(0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), feyi);
        assertEq(erc20.balanceOf(ganiyat), 100e18);
    }
}
