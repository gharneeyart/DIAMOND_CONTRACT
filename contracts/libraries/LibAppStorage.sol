// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AppStorage} from "../storage/AppStorage.sol";
import {LibDiamond} from "./LibDiamond.sol";

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly { ds.slot := 0 }
    }

    // True once initMultisig has been called and threshold is set.
    function multisigEnabled() internal view returns (bool) {
        return diamondStorage().threshold > 0;
    }

    // Only the diamond owner. Used for operational functions: mint, initERC20,
    // setTokenSVG, etc. Multisig has no say over these — they are not upgrades.
    function enforceOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    // Only a self-call originating from MultisigFacet.execute().
    // Used exclusively for signer management inside MultisigFacet.
    function enforceMultisig() internal view {
        require(msg.sender == address(this), "Only multisig");
    }
}
