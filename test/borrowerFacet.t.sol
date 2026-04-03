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
import "../contracts/facets/BorrowerFacet.sol";

contract BorrowerTest is DiamondUpgradeHelper {
    Diamond diamond;
    ERC721Facet nft;
    ERC20Facet erc20;
    BorrowerFacet borrower;
    address ganiyat;
    address feyi;

    function setUp() public {
        ganiyat = makeAddr("ganiyat");
        feyi = makeAddr("feyi");

        DiamondCutFacet dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));

        address[] memory addrs1 = new address[](3);
        addrs1[0] = address(new DiamondLoupeFacet());
        addrs1[1] = address(new OwnershipFacet());
        addrs1[2] = address(new ERC20Facet());

        string[] memory names1 = new string[](3);
        names1[0] = "DiamondLoupeFacet";
        names1[1] = "OwnershipFacet";
        names1[2] = "ERC20Facet";

        executeDiamondCut(IDiamondCut(address(diamond)), buildAddCutsByNames(addrs1, names1), address(0), "");

        IDiamondCut.FacetCut[] memory cuts2 = new IDiamondCut.FacetCut[](2);
        cuts2[0] = buildAddMissingCutByName(IDiamondLoupe(address(diamond)), address(new ERC721Facet()), "ERC721Facet");
        cuts2[1] = buildAddCutByName(address(new BorrowerFacet()), "BorrowerFacet");
        executeDiamondCut(IDiamondCut(address(diamond)), cuts2, address(0), "");

        nft = ERC721Facet(address(diamond));
        nft.init("OnChain", "OC");
        erc20 = ERC20Facet(address(diamond));
        erc20.initERC20("TestToken", "TT", 18);
        borrower = BorrowerFacet(address(diamond));
    }

    function testLendCreatesOffer() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        borrower.lend(0, 1 days, 10e18, 50e18);

        BorrowInfo memory info = borrower.borrowInfo(0);
        assertEq(info.lender, ganiyat);
        assertEq(info.duration, 1 days);
        assertEq(info.fee, 10e18);
        assertEq(info.collateral, 50e18);
    }

    function testCancelLendRemovesOffer() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        borrower.lend(0, 1 days, 10e18, 50e18);
        vm.prank(ganiyat);
        borrower.cancelLend(0);

        BorrowInfo memory info = borrower.borrowInfo(0);
        assertEq(info.lender, address(0));
    }

    function testBorrowRecordsBorrowerAndPays() public {
        nft.mint(ganiyat);
        vm.prank(ganiyat);
        borrower.lend(0, 1 days, 10e18, 50e18);

        // Fund feyi with ERC20 and approve diamond
        erc20.mint(feyi, 60e18);
        vm.startPrank(feyi);
        erc20.approve(address(diamond), 60e18);
        borrower.borrow(0);
        vm.stopPrank();

        BorrowInfo memory info = borrower.borrowInfo(0);
        assertEq(info.borrower, feyi);
        assertTrue(borrower.isActiveBorrow(0));
    }
}
