// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Script, console} from "forge-std/Script.sol";

import {BungeeApproveAndBridge, ISocketGateway} from "src/BungeeApproveAndBridge.sol";

contract DeployScript is Script {
    BungeeApproveAndBridge public bungeeApproveAndBridge;

    ISocketGateway constant SOCKET_GATEWAY = ISocketGateway(0x3a23F943181408EAC424116Af7b7790c94Cb97a5);

    function run() public {
        if (block.chainid == 1) {
            vm.broadcast();
            bungeeApproveAndBridge = new BungeeApproveAndBridge(SOCKET_GATEWAY);
            console.log("Deployed BungeeApproveAndBridge at: ", address(bungeeApproveAndBridge));
        } else {
            console.log("Skipping deployment of BungeeApproveAndBridge on network other than mainnet");
        }
    }
}
