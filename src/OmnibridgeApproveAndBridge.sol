// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IOmnibridge} from "./interface/IOmnibridge.sol";
import {ApproveAndBridge, IERC20} from "./mixin/ApproveAndBridge.sol";

/// @dev Based on:
/// <https://github.com/anxolin/cow-sdk-scripts/blob/feba22fffd2fe00b2f11a2781e5879712abc183d/src/contracts/omnibridge/index.ts>
contract OmnibridgeApproveAndBridge is ApproveAndBridge {
    IOmnibridge immutable omnibridge;

    constructor(IOmnibridge omnibridge_) {
        omnibridge = omnibridge_;
    }

    function bridgeApprovalTarget() public view override returns (address) {
        return address(omnibridge);
    }

    function bridge(IERC20 token, uint256 amount, address receiver) internal override {
        omnibridge.relayTokens(token, receiver, amount);
    }
}
