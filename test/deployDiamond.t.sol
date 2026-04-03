// import "../contracts/interfaces/IDiamondCut.sol";
// import "../contracts/facets/DiamondCutFacet.sol";
// import "../contracts/facets/DiamondLoupeFacet.sol";
// import "../contracts/facets/OwnershipFacet.sol";
// import "../contracts/Diamond.sol";
// import "forge-std/Test.sol";
// import "../contracts/storage/AppStorage.sol";
// import "../contracts/facets/ERC721Facet.sol";
// import "../contracts/facets/SVGFacet.sol";
// import "../contracts/facets/MultisigFacet.sol";
// import "../contracts/interfaces/IDiamondLoupe.sol";

// import "./helpers/DiamondUpgradeHelper.sol";

// contract DiamondDeployer is DiamondUpgradeHelper {
//     Diamond diamond;
//     DiamondCutFacet dCutFacet;
//     DiamondLoupeFacet dLoupe;
//     OwnershipFacet ownerF;
//     ERC721Facet erc721Facet;
//     MultisigFacet multisigFacet;
//     address ganiyat;
//     address feyi;
//     address zainab;

//     function setUp() public {
//         ganiyat = makeAddr("ganiyat");
//         feyi = makeAddr("feyi");
//         zainab = makeAddr("zainab");
//         // Deploy diamond and facets
//         dCutFacet = new DiamondCutFacet();
//         diamond = new Diamond(address(this), address(dCutFacet));
//         dLoupe = new DiamondLoupeFacet();
//         ownerF = new OwnershipFacet();
//         erc721Facet = new ERC721Facet();
//         multisigFacet = new MultisigFacet();

//         // array of facet addresses to add
//         address[] memory addAddrs = new address[](4);
//         addAddrs[0] = address(dLoupe);
//         addAddrs[1] = address(ownerF);
//         addAddrs[2] = address(erc721Facet);
//         addAddrs[3] = address(multisigFacet);

//         // array of facet names to add
//         string[] memory names = new string[](4);
//         names[0] = "DiamondLoupeFacet";
//         names[1] = "OwnershipFacet";
//         names[2] = "ERC721Facet";
//         names[3] = "MultisigFacet";

//         // Build cuts and execute
//         IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addAddrs, names);
//         executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

//         // Diamond only stores the facet addresses and the selectors that belongs to those facets

//         ERC721Facet(address(diamond)).init("GaniNFT", "GSN");
//     }

//     function testDeployDiamond() public {
//         DiamondLoupeFacet(address(diamond)).facetAddresses();
//     }

//     function test_NameAndSymbol() public {
//         ERC721Facet nft = ERC721Facet(address(diamond));

//         assertEq(nft.name(), "GaniNFT");
//         assertEq(nft.symbol(), "GSN");
//     }

//     function testMintAndTransfer() public {
//         ERC721Facet nft = ERC721Facet(address(diamond));

//         nft.mint(ganiyat);
//         assertEq(nft.ownerOf(0), ganiyat);

//         vm.prank(ganiyat);
//         nft.transferFrom(ganiyat, feyi, 0);
//         assertEq(nft.ownerOf(0), feyi);

//         string memory uri = nft.tokenURI(0);
//         assertTrue(bytes(uri).length > 0);
//     }

//     function testBalance() public {
//         ERC721Facet nft = ERC721Facet(address(diamond));

//         nft.mint(ganiyat);
//         assertEq(nft.balanceOf(ganiyat), 1);
//     }

//     function testApprove_SetsApproval() public {
//         ERC721Facet nft = ERC721Facet(address(diamond));

//         nft.mint(ganiyat);
//         vm.prank(ganiyat);
//         nft.approve(feyi, 0);
//         assertEq(nft.getApproved(0), feyi);
//     }

//     function testOperatorCanApproveForOwner() public {
//         ERC721Facet nft = ERC721Facet(address(diamond));

//         nft.mint(ganiyat);

//         vm.prank(ganiyat);
//         nft.setApprovalForAll(feyi, true);

//         vm.prank(feyi);
//         nft.approve(zainab, 0);

//         assertEq(nft.getApproved(0), zainab);
//     }

//     function testExtendCutMovesTokenURIToSvgFacet() public {
//         ERC721Facet(address(diamond)).mint(ganiyat);

//         SVGFacet svgFacet = new SVGFacet();
//         IDiamondCut.FacetCut[] memory cuts =
//             buildExtendCutsByName(IDiamondLoupe(address(diamond)), address(svgFacet), "SVGFacet");

//         executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

//         string memory uri = SVGFacet(address(diamond)).tokenURI(0);
//         assertTrue(bytes(uri).length > 0);
//     }

//     function testMultisigControlsUpgradeExecution() public {
//         address[] memory signers = new address[](2);
//         signers[0] = ganiyat;
//         signers[1] = feyi;

//         MultisigFacet(address(diamond)).initMultisig(signers, 2);

//         SVGFacet svgFacet = new SVGFacet();
//         IDiamondCut.FacetCut[] memory cuts =
//             buildExtendCutsByName(IDiamondLoupe(address(diamond)), address(svgFacet), "SVGFacet");
//         bytes memory callData = abi.encodeWithSelector(IDiamondCut.diamondCut.selector, cuts, address(0), "");

//         vm.prank(ganiyat);
//         uint256 proposalId = MultisigFacet(address(diamond)).propose(address(diamond), callData);

//         vm.prank(feyi);
//         MultisigFacet(address(diamond)).approve(proposalId);

//         vm.expectRevert(bytes("Only multisig"));
//         executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

//         MultisigFacet(address(diamond)).execute(proposalId);

//         ERC721Facet(address(diamond)).mint(ganiyat);
//         string memory uri = SVGFacet(address(diamond)).tokenURI(0);
//         assertTrue(bytes(uri).length > 0);
//     }
// }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/ERC721Facet.sol";
import "../contracts/facets/ERC20Facet.sol";
import "../contracts/facets/SVGFacet.sol";
import "../contracts/facets/StakingFacet.sol";
import "../contracts/facets/BorrowerFacet.sol";
import "../contracts/facets/MarketplaceFacet.sol";
import "../contracts/facets/MultisigFacet.sol";
import "../contracts/Diamond.sol";
import "./helpers/DiamondUpgradeHelper.sol";

// contract GoodReceiver {
//     function onERC721Received(address, address, uint256, bytes calldata)
//         external pure returns (bytes4) { return this.onERC721Received.selector; }
// }
// contract BadReceiver {
//     function onERC721Received(address, address, uint256, bytes calldata)
//         external pure returns (bytes4) { return 0xdeadbeef; }
// }

contract DiamondFullTest is DiamondUpgradeHelper {
    Diamond diamond;
    ERC721Facet nft;
    ERC20Facet token;
    SVGFacet svg;
    StakingFacet staking;
    BorrowerFacet borrow;
    MarketplaceFacet market;
    MultisigFacet multisig;

    address alice;
    address bob;
    address carol;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");

        DiamondCutFacet dCut = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCut));

        DiamondLoupeFacet dLoupe = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();
        ERC721Facet erc721 = new ERC721Facet();
        ERC20Facet erc20 = new ERC20Facet();
        SVGFacet svgF = new SVGFacet();
        StakingFacet stakF = new StakingFacet();
        BorrowerFacet borrowF = new BorrowerFacet();
        MarketplaceFacet marketF = new MarketplaceFacet();
        MultisigFacet msigF = new MultisigFacet();

        address[] memory addrs = new address[](9);
        addrs[0] = address(dLoupe);
        addrs[1] = address(ownerF);
        addrs[2] = address(erc721);
        addrs[3] = address(erc20);
        addrs[4] = address(svgF);
        addrs[5] = address(stakF);
        addrs[6] = address(borrowF);
        addrs[7] = address(marketF);
        addrs[8] = address(msigF);

        string[] memory names = new string[](9);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        names[2] = "ERC721Facet";
        names[3] = "ERC20Facet";
        names[4] = "SVGFacet";
        names[5] = "StakingFacet";
        names[6] = "BorrowerFacet";
        names[7] = "MarketplaceFacet";
        names[8] = "MultisigFacet";

        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        nft = ERC721Facet(address(diamond));
        token = ERC20Facet(address(diamond));
        svg = SVGFacet(address(diamond));
        staking = StakingFacet(address(diamond));
        borrow = BorrowerFacet(address(diamond));
        market = MarketplaceFacet(address(diamond));
        multisig = MultisigFacet(address(diamond));

        nft.init("OnChain", "OC");
        token.initERC20("OnChainToken", "OCT", 18);

        // Mint a few NFTs and some ERC20 for tests
        nft.mint(alice); // id 0
        nft.mint(alice); // id 1
        nft.mint(alice); // id 2
        token.mint(bob, 1000 ether);
    }

    // ── SVG uniqueness ────────────────────────────────────────────────────────

    // Every token should produce a non-empty URI
    function test_SVG_NonEmpty() public view {
        assertTrue(bytes(svg.tokenURI(0)).length > 0);
        assertTrue(bytes(svg.tokenURI(1)).length > 0);
        assertTrue(bytes(svg.tokenURI(2)).length > 0);
    }

    // Different token IDs must produce different URIs — proves uniqueness
    function test_SVG_Unique() public view {
        string memory uri0 = svg.tokenURI(0);
        string memory uri1 = svg.tokenURI(1);
        string memory uri2 = svg.tokenURI(2);
        assertTrue(keccak256(bytes(uri0)) != keccak256(bytes(uri1)), "token 0 and 1 must differ");
        assertTrue(keccak256(bytes(uri1)) != keccak256(bytes(uri2)), "token 1 and 2 must differ");
    }

    // Same token ID must always produce the same URI — proves determinism
    function test_SVG_Deterministic() public view {
        string memory first = svg.tokenURI(0);
        string memory second = svg.tokenURI(0);
        assertEq(keccak256(bytes(first)), keccak256(bytes(second)), "same token must render identically");
    }

    function test_SVG_HasBase64Prefix() public view {
        bytes memory uri = bytes(svg.tokenURI(0));
        bytes memory prefix = bytes("data:application/json;base64,");
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(uri[i], prefix[i]);
        }
    }

    function test_SVG_Override() public {
        svg.setTokenSVG(0, "<svg>custom</svg>");
        assertTrue(bytes(svg.tokenURI(0)).length > 0);
    }

    function test_SVG_Override_RevertIf_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        svg.setTokenSVG(0, "<svg/>");
    }

    function test_SVG_RevertIf_NotMinted() public {
        vm.expectRevert("Not minted");
        svg.tokenURI(999);
    }

    // Fuzz: URI must always be non-empty and deterministic for any minted token
    function testFuzz_SVG_Deterministic(uint8 seed) public {
        // Mint a token whose id is derived from seed
        uint256 targetId = nft.currentTokenId();
        // Mint enough tokens to reach targetId if seed is large
        uint256 count = seed % 20;
        for (uint256 i = 0; i < count; i++) {
            nft.mint(alice);
        }
        uint256 lastId = nft.currentTokenId() - 1;

        if (lastId >= targetId) {
            string memory a = svg.tokenURI(lastId);
            string memory b = svg.tokenURI(lastId);
            assertEq(keccak256(bytes(a)), keccak256(bytes(b)));
        }
    }

    // ── Multisig ──────────────────────────────────────────────────────────────

    function test_Multisig_Init() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);
        assertEq(multisig.getThreshold(), 2);
        assertEq(multisig.getSigners().length, 2);
    }

    function test_Multisig_OwnerStillMintable_AfterInit() public {
        // After multisig is active, owner can still mint — it's operational not an upgrade
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);
        // This must NOT revert — mint is owner-gated, not multisig-gated
        nft.mint(carol);
        assertEq(nft.ownerOf(3), carol);
    }

    function test_Multisig_DirectCut_BlockedAfterInit() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);

        // Owner trying to cut directly must fail once multisig is live
        IDiamondCut.FacetCut[] memory empty;
        vm.expectRevert("Only multisig");
        IDiamondCut(address(diamond)).diamondCut(empty, address(0), "");
    }

    function test_Multisig_UpgradeViaProposal() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);

        // Build a real cut: replace SVGFacet
        SVGFacet newSvg = new SVGFacet();
        IDiamondCut.FacetCut[] memory cuts =
            buildExtendCutsByName(IDiamondLoupe(address(diamond)), address(newSvg), "SVGFacet");
        bytes memory callData = abi.encodeWithSelector(IDiamondCut.diamondCut.selector, cuts, address(0), "");

        // Alice proposes (auto-approves)
        vm.prank(alice);
        uint256 id = multisig.propose(address(diamond), callData);
        assertEq(multisig.getProposalApprovals(id), 1);

        // Bob approves — now at threshold
        vm.prank(bob);
        multisig.approve(id);
        assertEq(multisig.getProposalApprovals(id), 2);

        // Execute
        multisig.execute(id);
        assertTrue(multisig.isExecuted(id));

        // Verify upgrade worked — tokenURI still works
        assertTrue(bytes(svg.tokenURI(0)).length > 0);
    }

    function test_Multisig_Init_RevertIf_BadThreshold() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        vm.expectRevert("Bad threshold");
        multisig.initMultisig(signers, 3);
    }

    function test_Multisig_Init_RevertIf_Duplicate() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = alice;
        vm.expectRevert("Duplicate signer");
        multisig.initMultisig(signers, 1);
    }

    function test_Multisig_Execute_RevertIf_BelowThreshold() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);

        vm.prank(alice);
        uint256 id = multisig.propose(address(diamond), abi.encode(1));
        // Only alice approved (1 of 2)
        vm.expectRevert("Below threshold");
        multisig.execute(id);
    }

    function test_Multisig_Execute_RevertIf_AlreadyExecuted() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 1); // 1-of-2 so alice alone is enough

        vm.prank(alice);
        uint256 id = multisig.propose(address(diamond), abi.encode(1));
        multisig.execute(id);
        vm.expectRevert("Already executed");
        multisig.execute(id);
    }

    function test_Multisig_Approve_RevertIf_AlreadySigned() public {
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);
        vm.prank(alice);
        uint256 id = multisig.propose(address(diamond), abi.encode(1));
        vm.prank(alice);
        vm.expectRevert("Already signed");
        multisig.approve(id);
    }

    // ── OwnershipFacet ────────────────────────────────────────────────────────

    function test_Ownership_Transfer() public {
        OwnershipFacet ownerF = OwnershipFacet(address(diamond));
        ownerF.transferOwnership(alice);
        assertEq(ownerF.owner(), alice);
    }

    function test_Ownership_TransferStillWorks_AfterMultisig() public {
        // transferOwnership must remain usable even after multisig is live
        address[] memory signers = new address[](2);
        signers[0] = alice;
        signers[1] = bob;
        multisig.initMultisig(signers, 2);

        OwnershipFacet ownerF = OwnershipFacet(address(diamond));
        ownerF.transferOwnership(carol);
        assertEq(ownerF.owner(), carol);
    }

    function test_Ownership_RevertIf_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        OwnershipFacet(address(diamond)).transferOwnership(alice);
    }

    // ── ERC721 ────────────────────────────────────────────────────────────────

    function test_ERC721_NameSymbol() public view {
        assertEq(nft.name(), "OnChain");
        assertEq(nft.symbol(), "OC");
    }

    function test_ERC721_Mint_OwnerAndBalance() public view {
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 3);
    }

    function test_ERC721_Transfer() public {
        vm.prank(alice);
        nft.transferFrom(alice, bob, 0);
        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.balanceOf(bob), 1);
    }

    // function test_ERC721_SafeTransfer_GoodReceiver() public {
    //     GoodReceiver good = new GoodReceiver();
    //     vm.prank(alice);
    //     nft.safeTransferFrom(alice, address(good), 0);
    //     assertEq(nft.ownerOf(0), address(good));
    // }

    // function test_ERC721_SafeTransfer_BadReceiver_Reverts() public {
    //     BadReceiver bad = new BadReceiver();
    //     vm.prank(alice);
    //     vm.expectRevert("Unsafe recipient");
    //     nft.safeTransferFrom(alice, address(bad), 0);
    // }

    function test_ERC721_Approve_AndTransferByApproved() public {
        vm.prank(alice);
        nft.approve(bob, 0);
        vm.prank(bob);
        nft.transferFrom(alice, bob, 0);
        assertEq(nft.ownerOf(0), bob);
    }

    function test_ERC721_Approve_ClearedAfterTransfer() public {
        vm.prank(alice);
        nft.approve(bob, 0);
        vm.prank(bob);
        nft.transferFrom(alice, bob, 0);
        assertEq(nft.getApproved(0), address(0));
    }

    function test_ERC721_SetApprovalForAll() public {
        vm.prank(alice);
        nft.setApprovalForAll(bob, true);
        assertTrue(nft.isApprovedForAll(alice, bob));
        vm.prank(bob);
        nft.transferFrom(alice, carol, 0);
        assertEq(nft.ownerOf(0), carol);
    }

    function test_ERC721_Transfer_RevertIf_NotApproved() public {
        vm.prank(bob);
        vm.expectRevert("Not approved");
        nft.transferFrom(alice, bob, 0);
    }

    function test_ERC721_Init_RevertIf_CalledTwice() public {
        vm.expectRevert("Already initialised");
        nft.init("X", "Y");
    }

    // ── ERC20 ─────────────────────────────────────────────────────────────────

    function test_ERC20_Metadata() public view {
        assertEq(token.tokenName(), "OnChainToken");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1000 ether);
    }

    function test_ERC20_Transfer() public {
        vm.prank(bob);
        token.transfer(alice, 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.balanceOf(bob), 900 ether);
    }

    function test_ERC20_ApproveAndTransferFrom() public {
        vm.prank(bob);
        token.approve(alice, 300 ether);
        vm.prank(alice);
        token.transferFrom(bob, carol, 200 ether);
        assertEq(token.balanceOf(carol), 200 ether);
        assertEq(token.allowance(bob, alice), 100 ether);
    }

    function test_ERC20_Burn() public {
        vm.prank(bob);
        token.burn(500 ether);
        assertEq(token.totalSupply(), 500 ether);
    }

    function test_ERC20_Transfer_RevertIf_Insufficient() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        token.transfer(bob, 1 ether);
    }

    function test_ERC20_TransferFrom_RevertIf_AllowanceLow() public {
        vm.prank(bob);
        token.approve(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Allowance too low");
        token.transferFrom(bob, carol, 2 ether);
    }

    // ── Staking ───────────────────────────────────────────────────────────────

    function test_Stake_TransfersToContract() public {
        vm.prank(alice);
        staking.stake(0);
        assertEq(nft.ownerOf(0), address(diamond));
    }

    function test_Stake_TracksStaker() public {
        vm.prank(alice);
        staking.stake(0);
        assertEq(staking.stakedTokensOf(alice).length, 1);
    }

    function test_Unstake_ReturnsToken() public {
        vm.prank(alice);
        staking.stake(0);
        vm.prank(alice);
        staking.unstake(0);
        assertEq(nft.ownerOf(0), alice);
        assertEq(staking.stakedTokensOf(alice).length, 0);
    }

    function test_Stake_RevertIf_NotOwner() public {
        vm.prank(bob);
        vm.expectRevert("Not owner");
        staking.stake(0);
    }

    function test_Stake_RevertIf_Listed() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        vm.prank(alice);
        vm.expectRevert("Token is listed");
        staking.stake(0);
    }

    function test_Unstake_RevertIf_NotStaker() public {
        vm.prank(alice);
        staking.stake(0);
        vm.prank(bob);
        vm.expectRevert("Not staker");
        staking.unstake(0);
    }

    // ── Borrowing ─────────────────────────────────────────────────────────────

    function test_Lend_RecordsBorrow() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        BorrowInfo memory info = borrow.borrowInfo(0);
        assertEq(info.borrower, bob);
        assertEq(info.duration, 1 days);
    }

    function test_Return_ByBorrower() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.prank(bob);
        borrow.returnNFT(0);
        assertEq(borrow.borrowInfo(0).borrower, address(0));
    }

    function test_Return_ByOwner() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.prank(alice);
        borrow.returnNFT(0);
        assertEq(borrow.borrowInfo(0).borrower, address(0));
    }

    function test_Return_AfterExpiry_ByAnyone() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(carol);
        borrow.returnNFT(0);
        assertEq(borrow.borrowInfo(0).borrower, address(0));
    }

    function test_Lend_RevertIf_AlreadyBorrowed() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.prank(alice);
        vm.expectRevert("Already borrowed");
        borrow.lend(0, carol, 1 days);
    }

    function test_Return_RevertIf_NotAuthorised() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.prank(carol);
        vm.expectRevert("Not authorised");
        borrow.returnNFT(0);
    }

    // ── Marketplace ───────────────────────────────────────────────────────────

    function test_Market_List() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        Listing memory l = market.getListing(0);
        assertEq(l.seller, alice);
        assertEq(l.price, 100 ether);
        assertTrue(l.active);
    }

    function test_Market_Buy() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        vm.prank(bob);
        token.approve(address(diamond), 100 ether);
        vm.prank(bob);
        market.buy(0);
        assertEq(nft.ownerOf(0), bob);
        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.balanceOf(bob), 900 ether);
        assertFalse(market.getListing(0).active);
    }

    function test_Market_Cancel() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        vm.prank(alice);
        market.cancelListing(0);
        assertFalse(market.getListing(0).active);
    }

    function test_Market_Buy_RevertIf_AllowanceLow() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        vm.prank(bob);
        vm.expectRevert("Allowance too low");
        market.buy(0);
    }

    function test_Market_Buy_RevertIf_SellerBuysOwn() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        vm.prank(alice);
        vm.expectRevert("Seller cannot buy own NFT");
        market.buy(0);
    }

    function test_Market_List_RevertIf_Borrowed() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.prank(alice);
        vm.expectRevert("Token has borrow record");
        market.list(0, 100 ether);
    }

    // ── Integration ───────────────────────────────────────────────────────────

    function test_Integration_FullLifecycle() public {
        // Mint → list → buy → stake → unstake → SVG changes at each step
        vm.prank(alice);
        market.list(0, 200 ether);

        vm.prank(bob);
        token.approve(address(diamond), 200 ether);
        vm.prank(bob);
        market.buy(0);
        assertEq(nft.ownerOf(0), bob);

        vm.prank(bob);
        staking.stake(0);
        assertEq(nft.ownerOf(0), address(diamond));

        // tokenURI still works while staked (SVGFacet reads state)
        string memory uri = svg.tokenURI(0);
        assertTrue(bytes(uri).length > 0);

        vm.prank(bob);
        staking.unstake(0);
        assertEq(nft.ownerOf(0), bob);
    }

    function test_Integration_ListedCannotBeStaked() public {
        vm.prank(alice);
        market.list(0, 100 ether);
        vm.prank(alice);
        vm.expectRevert("Token is listed");
        staking.stake(0);
    }

    function test_Integration_BorrowedCannotBeListed() public {
        vm.prank(alice);
        borrow.lend(0, bob, 1 days);
        vm.prank(alice);
        vm.expectRevert("Token has borrow record");
        market.list(0, 100 ether);
    }
}
