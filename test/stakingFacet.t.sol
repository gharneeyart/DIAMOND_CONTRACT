// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/Diamond.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "./helpers/DiamondUpgradeHelper.sol";
import "../contracts/facets/StakingFacet.sol";

contract StakingTest is DiamondUpgradeHelper {
    Diamond diamond;
    ERC721Facet nft;
    StakingFacet staking;
    address ganiyat;

    function setUp() public {
        ganiyat = makeAddr("ganiyat");

        DiamondCutFacet dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));

        address[] memory addrs = new address[](4);
        addrs[0] = address(new DiamondLoupeFacet());
        addrs[1] = address(new OwnershipFacet());
        addrs[2] = address(new ERC721Facet());
        addrs[3] = address(new StakingFacet());

        string[] memory names = new string[](4);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        names[2] = "ERC721Facet";
        names[3] = "StakingFacet";

        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        nft = ERC721Facet(address(diamond));
        nft.init("OnChainNFT", "OCN");
        staking = StakingFacet(address(diamond));
    }

    function testStakeTransfersNFTToDiamond() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        staking.stake(0);
        assertEq(nft.ownerOf(0), address(diamond));
    }

    function testUnstakeReturnsNFTToStaker() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        staking.stake(0);
        vm.prank(ganiyat);
        staking.unstake(0);
        assertEq(nft.ownerOf(0), ganiyat);
    }

    function testStakedTokensOfTracksMultipleStakes() public {
        nft.mint(ganiyat);
        nft.mint(ganiyat);
        vm.startPrank(ganiyat);
        staking.stake(0);
        staking.stake(1);
        vm.stopPrank();
        uint256[] memory tokens = staking.stakedTokensOf(ganiyat);
        assertEq(tokens.length, 2);
        assertEq(tokens[0], 0);
        assertEq(tokens[1], 1);
    }
}
