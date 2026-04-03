// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage, Proposal} from "../storage/AppStorage.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

// MultisigFacet replaces the single-owner upgrade pattern.
// Instead of one address controlling diamondCut, N-of-M signers must agree.
// The old contractOwner in LibDiamond is kept for bootstrapping (it can add
// the initial signers), but after that it should not be used for upgrades.
contract MultisigFacet {
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event ThresholdChanged(uint256 newThreshold);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event ProposalApproved(uint256 indexed proposalId, address indexed signer);
    event ProposalExecuted(uint256 indexed proposalId);

    // Bootstrap: called once by the diamond owner to set up the multisig.
    function initMultisig(address[] calldata _signers, uint256 _threshold) external {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_threshold > 0 && _threshold <= _signers.length, "Bad threshold");
        require(s.signers.length == 0, "Already initialised");

        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Zero signer");
            require(!s.isSigner[_signers[i]], "Duplicate signer");
            s.isSigner[_signers[i]] = true;
            s.signers.push(_signers[i]);
        }

        s.threshold = _threshold;
        // LibDiamond.setContractOwner(address(0));
    }

    // Any current signer proposes an upgrade.
    // `_callData` is the ABI-encoded diamondCut call.
    function propose(address _target, bytes calldata _callData) external returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.isSigner[msg.sender], "Not signer");
        // require(_target == address(this), "Target must be diamond");
        require(_callData.length > 0, "Empty calldata");

        uint256 id = s.proposalCount++;
        Proposal storage p = s.proposals[id];
        p.proposer = msg.sender;
        p.target = _target;
        p.callData = _callData;
        p.executed = false;
        p.approvals = 1;
        p.hasSigned[msg.sender] = true;

        emit ProposalCreated(id, msg.sender);
        emit ProposalApproved(id, msg.sender);
        return id;
    }

    // Any signer approves a pending proposal.
    function approve(uint256 proposalId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.isSigner[msg.sender], "Not signer");

        Proposal storage p = s.proposals[proposalId];
        require(p.target != address(0), "Unknown proposal");
        require(!p.executed, "Already executed");
        require(!p.hasSigned[msg.sender], "Already signed");

        p.hasSigned[msg.sender] = true;
        p.approvals += 1;

        emit ProposalApproved(proposalId, msg.sender);
    }

    // Anyone can trigger execution once threshold is met.
    function execute(uint256 proposalId) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        Proposal storage p = s.proposals[proposalId];
        require(p.target != address(0), "Unknown proposal");
        require(!p.executed, "Already executed");
        require(p.approvals >= s.threshold, "Below threshold");

        // Mark as executed BEFORE the call to prevent reentrancy.
        p.executed = true;

        // Execute the proposed call (e.g., a diamondCut upgrade).
        (bool ok, bytes memory err) = p.target.call(p.callData);
        require(ok, string(err));

        emit ProposalExecuted(proposalId);
    }

    // Signer changes are themselves governance actions, so they must come from
    // the diamond after a successful multisig proposal.
    function addSigner(address signer) external {
        // require(msg.sender == address(this), "Only multisig");
        LibAppStorage.enforceMultisig();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(signer != address(0), "Zero signer");
        require(!s.isSigner[signer], "Already signer");
        s.isSigner[signer] = true;
        s.signers.push(signer);
        emit SignerAdded(signer);
    }

    // Signer removal is also governance-only.
    function removeSigner(address signer) external {
        LibAppStorage.enforceMultisig();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.isSigner[signer], "Not signer");
        require(s.signers.length - 1 >= s.threshold, "Would break threshold");

        s.isSigner[signer] = false;
        // Remove from array (swap-and-pop).
        for (uint256 i = 0; i < s.signers.length; i++) {
            if (s.signers[i] == signer) {
                s.signers[i] = s.signers[s.signers.length - 1];
                s.signers.pop();
                break;
            }
        }
        emit SignerRemoved(signer);
    }

    function changeThreshold(uint256 newThreshold) external {
        // require(msg.sender == address(this), "Only multisig");
        LibAppStorage.enforceMultisig();
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(newThreshold > 0 && newThreshold <= s.signers.length, "Bad threshold");
        s.threshold = newThreshold;
        emit ThresholdChanged(newThreshold);
    }

    function getSigners() external view returns (address[] memory) {
        return LibAppStorage.diamondStorage().signers;
    }

    function getThreshold() external view returns (uint256) {
        return LibAppStorage.diamondStorage().threshold;
    }

    function getProposalApprovals(uint256 proposalId) external view returns (uint256) {
        return LibAppStorage.diamondStorage().proposals[proposalId].approvals;
    }

    function isExecuted(uint256 proposalId) external view returns (bool) {
        return LibAppStorage.diamondStorage().proposals[proposalId].executed;
    }
}
