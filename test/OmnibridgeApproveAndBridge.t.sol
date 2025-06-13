// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Test, console} from "forge-std/Test.sol";

import {IOmnibridge, OmnibridgeApproveAndBridge} from "src/OmnibridgeApproveAndBridge.sol";

contract OmnibridgeApproveAndBridgeTest is Test {
    OmnibridgeApproveAndBridge public approveAndBridge;
    IOmnibridge omnibridge;

    function setUp() public {
        omnibridge = IOmnibridge(makeAddr("OmnibridgeApproveAndBridgeTest: omnibridge"));
        approveAndBridge = new OmnibridgeApproveAndBridge(omnibridge);
    }
}
