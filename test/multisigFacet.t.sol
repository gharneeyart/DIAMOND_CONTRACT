// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "../contracts/Diamond.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/interfaces/IDiamondLoupe.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/MultisigFacet.sol";
import "./helpers/DiamondUpgradeHelper.sol";

contract MultisigTest is DiamondUpgradeHelper {
    Diamond diamond;
    MultisigFacet multisig;
    address signer1;
    address signer2;
    address signer3;

    function setUp() public {
        signer1 = makeAddr("signer1");
        signer2 = makeAddr("signer2");
        signer3 = makeAddr("signer3");

        DiamondCutFacet dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));

        address[] memory addrs = new address[](3);
        addrs[0] = address(new DiamondLoupeFacet());
        addrs[1] = address(new OwnershipFacet());
        addrs[2] = address(new MultisigFacet());

        string[] memory names = new string[](3);
        names[0] = "DiamondLoupeFacet";
        names[1] = "OwnershipFacet";
        names[2] = "MultisigFacet";

        IDiamondCut.FacetCut[] memory cuts = buildAddCutsByNames(addrs, names);
        executeDiamondCut(IDiamondCut(address(diamond)), cuts, address(0), "");

        multisig = MultisigFacet(address(diamond));

        address[] memory signers = new address[](3);
        signers[0] = signer1;
        signers[1] = signer2;
        signers[2] = signer3;
        multisig.initMultisig(signers, 2);
    }

    function testInitSetsSignersAndThreshold() public {
        address[] memory signers = multisig.getSigners();
        assertEq(signers.length, 3);
        assertEq(multisig.getThreshold(), 2);
    }

    function testProposeCreatesProposalWithOneApproval() public {
        bytes memory callData = abi.encodeWithSelector(MultisigFacet.changeThreshold.selector, 2);
        vm.prank(signer1);
        uint256 id = multisig.propose(address(diamond), callData);

        assertEq(multisig.getProposalApprovals(id), 1);
        assertFalse(multisig.isExecuted(id));
    }

    function testApproveIncrementsApprovals() public {
        bytes memory callData = abi.encodeWithSelector(MultisigFacet.changeThreshold.selector, 2);
        vm.prank(signer1);
        uint256 id = multisig.propose(address(diamond), callData);

        vm.prank(signer2);
        multisig.approve(id);

        assertEq(multisig.getProposalApprovals(id), 2);
    }
}
