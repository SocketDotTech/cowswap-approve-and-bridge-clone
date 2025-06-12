// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IERC20} from "../vendored/IERC20.sol";

/// @dev See:
/// <https://etherscan.io/address/0x8eB3b7D8498a6716904577b2579e1c313d48E347#code#L1068>
interface IOmnibridge {
    /// @dev bridge and send to receiver
    function relayTokens(IERC20 token, address receiver, uint256 value) external;
}
