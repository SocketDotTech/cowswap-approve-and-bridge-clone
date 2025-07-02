// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IApproveAndBridge} from "../interface/IApproveAndBridge.sol";
import {IERC20} from "../vendored/IERC20.sol";
import {SafeERC20} from "../vendored/SafeERC20.sol";

abstract contract ApproveAndBridge is IApproveAndBridge {
    using SafeERC20 for IERC20;

    /// @dev This function isn't intended to be called directly, it should be
    /// delegatecalled instead.
    function approveAndBridge(IERC20 token, uint256 minAmount, address receiver, uint256 toChainId, bytes calldata data)
        external
    {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= minAmount, "Bridging less than min amount");

        token.forceApprove(bridgeApprovalTarget(), balance);

        bridge(token, balance, receiver, toChainId, data);
    }

    function bridgeApprovalTarget() public view virtual returns (address);

    function bridge(IERC20 token, uint256 amount, address receiver, uint256 toChainId, bytes calldata data)
        internal
        virtual;
}
