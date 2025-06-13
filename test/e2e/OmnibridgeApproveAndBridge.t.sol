// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {Test, Vm} from "forge-std/Test.sol";

import {IERC20, IOmnibridge, OmnibridgeApproveAndBridge} from "src/OmnibridgeApproveAndBridge.sol";
import {IApproveAndBridge} from "src/interface/IApproveAndBridge.sol";

import {ForkedRpc} from "./lib/ForkedRpc.sol";

interface COWShedFactory {
    function initializeProxy(address user, bool withEns) external;
    function proxyOf(address who) external view returns (address);
}

interface COWShed {
    struct Call {
        address target;
        uint256 value;
        bytes callData;
        bool allowFailure;
        bool isDelegateCall;
    }

    function trustedExecuteHooks(Call[] calldata calls) external;
}

interface IOmnibridgeEvents {
    event TokensBridgingInitiated(
        address indexed token, address indexed sender, uint256 value, bytes32 indexed messageId
    );
}

contract E2EOmnibridgeApproveAndBridgeTest is Test {
    using ForkedRpc for Vm;

    uint256 private constant MAINNET_FORK_BLOCK = 22689062;
    IOmnibridge constant OMNIBRIDGE = IOmnibridge(0x88ad09518695c6c3712AC10a214bE5109a655671);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // https://github.com/cowdao-grants/cow-shed/blob/96cbe1ef68f5fd16a3d2899a13cd3dca52444c17/networks.json
    COWShedFactory constant factory = COWShedFactory(0x00E989b87700514118Fa55326CD1cCE82faebEF6);
    address constant user = 0xE68d531d8B4d035bf3F4BC2DaBb70f51FbB14E23; // Some WETH holder

    OmnibridgeApproveAndBridge public approveAndBridge;
    address public receiver;

    function setUp() public {
        vm.label(user, "user");
        vm.label(address(OMNIBRIDGE), "omnibridge");
        vm.label(address(WETH), "WETH");

        vm.forkEthereumMainnetAtBlock(MAINNET_FORK_BLOCK);
        approveAndBridge = new OmnibridgeApproveAndBridge(OMNIBRIDGE);
        receiver = makeAddr("E2EOmnibridgeApproveAndBridgeTest: receiver");
    }

    function test_happyPath() external {
        // Note: deployment and initialization is handled in `executeHooks` and
        // doesn't need to be done in the actual trade setting.
        // However, it's easier to build the test without handling the
        // authentication part needed for that and use `trustedExecuteHooks`
        // through the factory instead.
        factory.initializeProxy(user, false);
        COWShed shed = COWShed(factory.proxyOf(user));
        vm.label(address(shed), "shed");
        assertGt(address(shed).code.length, 0);

        uint256 orderProceeds = 1_337 ether;
        uint256 minProceeds = 42 ether;
        assertGt(orderProceeds, minProceeds);

        // For simplicity we take the funds from the user, but they should come
        // from an order.
        vm.prank(user);
        WETH.transfer(address(shed), orderProceeds);
        assertEq(WETH.balanceOf(address(shed)), orderProceeds);

        COWShed.Call[] memory calls = new COWShed.Call[](1);
        calls[0] = COWShed.Call({
            target: address(approveAndBridge),
            value: 0,
            callData: abi.encodeCall(IApproveAndBridge.approveAndBridge, (WETH, minProceeds, receiver)),
            allowFailure: false,
            isDelegateCall: true
        });

        vm.prank(address(factory));
        // Note: index 3 is `messageId`, an omnibridge implementation detail
        // which we don't want to test here.
        vm.expectEmit(true, true, false, true, address(OMNIBRIDGE));
        emit IOmnibridgeEvents.TokensBridgingInitiated({
            token: address(WETH),
            sender: address(shed),
            value: orderProceeds,
            messageId: bytes32(0)
        });
        shed.trustedExecuteHooks(calls);
        assertEq(WETH.balanceOf(address(shed)), 0);
    }

    function test_notEnoughFunds() external {
        // Note: deployment and initialization is handled in `executeHooks` and
        // doesn't need to be done in the actual trade setting.
        // However, it's easier to build the test without handling the
        // authentication part needed for that and use `trustedExecuteHooks`
        // through the factory instead.
        factory.initializeProxy(user, false);
        COWShed shed = COWShed(factory.proxyOf(user));
        vm.label(address(shed), "shed");
        assertGt(address(shed).code.length, 0);

        uint256 minProceeds = 42 ether;

        vm.prank(user);
        WETH.transfer(address(shed), minProceeds - 1);

        COWShed.Call[] memory calls = new COWShed.Call[](1);
        calls[0] = COWShed.Call({
            target: address(approveAndBridge),
            value: 0,
            callData: abi.encodeCall(IApproveAndBridge.approveAndBridge, (WETH, minProceeds, receiver)),
            allowFailure: false,
            isDelegateCall: true
        });

        vm.prank(address(factory));
        vm.expectRevert("Bridging less than min amount");
        shed.trustedExecuteHooks(calls);
        assertEq(WETH.balanceOf(address(shed)), minProceeds - 1);

        // The same hook can still be used if more funds become available
        vm.prank(user);
        WETH.transfer(address(shed), 1);
        vm.prank(address(factory));
        shed.trustedExecuteHooks(calls);
        assertEq(WETH.balanceOf(address(shed)), 0);
    }
}
