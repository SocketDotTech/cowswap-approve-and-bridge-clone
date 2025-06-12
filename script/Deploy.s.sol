// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Script, console} from "forge-std/Script.sol";

import {IOmnibridge, OmnibridgeApproveAndBridge} from "src/OmnibridgeApproveAndBridge.sol";

contract DeployScript is Script {
    OmnibridgeApproveAndBridge public omnibridgeApproveAndBridge;

    IOmnibridge constant MAINNET_OMNIBRIDGE = IOmnibridge(0x88ad09518695c6c3712AC10a214bE5109a655671);

    function run() public {
        if (block.chainid == 1) {
            vm.broadcast();
            omnibridgeApproveAndBridge = new OmnibridgeApproveAndBridge(MAINNET_OMNIBRIDGE);
        }
    }
}
