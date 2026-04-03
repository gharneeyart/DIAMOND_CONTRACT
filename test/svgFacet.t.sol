// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "../contracts/Diamond.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/SVGFacet.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract SVGTest is DiamondUpgradeHelper {
    Diamond diamond;
    ERC721Facet nft;
    SVGFacet svg;
    address ganiyat;
    address feyi;

    function setUp() public {
        ganiyat = makeAddr("ganiyat");
        feyi = makeAddr("feyi");

        DiamondCutFacet dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));

        address[] memory addrs = new address[](4);
        addrs[0] = address(new DiamondLoupeFacet());
        addrs[1] = address(new OwnershipFacet());
        addrs[2] = address(new ERC721Facet());
        addrs[3] = address(new SVGFacet());

        string[] memory names = new string[](4);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        names[2] = "ERC721Facet";
        names[3] = "SVGFacet";

        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        nft = ERC721Facet(address(diamond));
        nft.init("OnChain", "OC");
        svg = SVGFacet(address(diamond));
    }

    function testTokenURIReturnsDataURI() public {
        nft.mint(ganiyat);
        string memory uri = svg.tokenURI(0);
        // Must start with the base64 JSON data URI prefix
        bytes memory prefix = bytes("data:application/json;base64,");
        bytes memory uriBytes = bytes(uri);
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(uriBytes[i], prefix[i]);
        }
    }

    function testSetTokenSVGOverridesDefault() public {
        nft.mint(ganiyat);
        string memory defaultURI = svg.tokenURI(0);
        svg.setTokenSVG(0, "<svg>custom</svg>");
        string memory customURI = svg.tokenURI(0);
        assertTrue(keccak256(bytes(defaultURI)) != keccak256(bytes(customURI)));
    }

    function testTokenURIRevertsForUnmintedToken() public {
        vm.expectRevert("Not minted");
        svg.tokenURI(999);
    }

    function testTokenMintUniqueSVG() public {
        nft.mint(ganiyat);
        nft.mint(feyi);
        string memory uri1 = svg.tokenURI(0);
        string memory uri2 = svg.tokenURI(1);
        assertTrue(keccak256(bytes(uri1)) != keccak256(bytes(uri2)));
    }
}
