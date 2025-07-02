// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

/// @dev See:
/// https://arbiscan.io/address/0x69D9f76e4cbE81044FE16C399387b12e4DBF27B1#code
interface ISocketVerifier {
    struct SocketRequest {
        uint256 amount;
        address recipient;
        uint256 toChainId;
        address token;
        bytes4 signature;
    }

    function validateSocketRequest(bytes calldata callData, SocketRequest calldata expectedRequest) external;
}
