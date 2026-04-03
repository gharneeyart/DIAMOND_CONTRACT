// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../contracts/Diamond.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract ERC20Test is DiamondUpgradeHelper {
    Diamond diamond;
    ERC20Facet erc20;
    address ganiyat;
    address ganiyu;

    function setUp() public {
        ganiyat = makeAddr("ganiyat");
        ganiyu = makeAddr("ganiyu");

        DiamondCutFacet dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));

        address[] memory addrs = new address[](3);
        addrs[0] = address(new DiamondLoupeFacet());
        addrs[1] = address(new OwnershipFacet());
        addrs[2] = address(new ERC20Facet());

        string[] memory names = new string[](3);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        names[2] = "ERC20Facet";

        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        erc20 = ERC20Facet(address(diamond));
        erc20.initERC20("GaniToken", "GT", 18);
    }

    function testInitStoresNameSymbolDecimals() public {
        assertEq(erc20.tokenName(), "GaniToken");
        assertEq(erc20.tokenSymbol(), "GT");
        assertEq(erc20.decimals(), 18);
    }

    function testMintIncreasesBalanceAndSupply() public {
        erc20.mint(ganiyat, 1000e18);
        assertEq(erc20.balanceOf(ganiyat), 1000e18);
        assertEq(erc20.totalSupply(), 1000e18);
    }

    function testTransferMovesTokens() public {
        erc20.mint(ganiyat, 500e18);
        vm.prank(ganiyat);
        erc20.transfer(ganiyu, 200e18);
        assertEq(erc20.balanceOf(ganiyat), 300e18);
        assertEq(erc20.balanceOf(ganiyu), 200e18);
    }
}
