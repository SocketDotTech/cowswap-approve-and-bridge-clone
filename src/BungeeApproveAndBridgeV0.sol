// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {ISocketGateway} from "./interface/ISocketGateway.sol";
import {ApproveAndBridge, IERC20} from "./mixin/ApproveAndBridge.sol";

/// ! @dev UNAUDITED UNTESTED Do not use in production
/// @dev Performs one steps before bridging:
/// 1. Modify input amount in calldata
contract BungeeApproveAndBridge is ApproveAndBridge {
    error InvalidInput();
    error PositionOutOfBounds();
    error BridgeFailed();

    ISocketGateway immutable socketGateway;

    constructor(ISocketGateway socketGateway_) {
        socketGateway = socketGateway_;
    }

    function bridgeApprovalTarget() public view override returns (address) {
        return address(socketGateway);
    }

    function bridge(IERC20 token, uint256 amount, address receiver, bytes calldata data) internal override {
        // decode & parse data to find positions in calldata to modify
        bytes memory modifiedCalldata = _parseAndModifyCalldata(amount, data);

        // execute using the modified calldata via SocketGateway.fallback()
        (bool success,) = address(socketGateway).call(modifiedCalldata);
        if (!success) revert BridgeFailed();
    }

    function _parseAndModifyCalldata(uint256 amount, bytes calldata data) internal pure returns (bytes memory) {
        // decode data as calldata for SocketGateway.fallback()

        // Next: routeExecutionCalldata (up to data.length - extraDataLength)
        uint256 extraDataLength = 32;
        if (data.length < 4 + extraDataLength) revert InvalidInput();
        bytes memory routeExecutionCalldata = data[4:data.length - extraDataLength];

        // 2. Decode the extra data struct
        bytes memory extraData = data[data.length - 32 * 4:];
        (uint256 inputAmountStartIndex) = abi.decode(extraData, (uint256));

        // 4. Replace input amount in calldata
        bytes memory modifiedCalldata =
            _replaceUint256({_original: routeExecutionCalldata, _start: inputAmountStartIndex, _amount: amount});

        return modifiedCalldata;
    }

    function _replaceUint256(bytes memory _original, uint256 _start, uint256 _amount)
        internal
        pure
        returns (bytes memory)
    {
        // check if the _start is out of bounds
        if (_start + 32 > _original.length) revert PositionOutOfBounds();

        // Directly modify externalData in-place without creating a new copy
        assembly {
            // Calculate position in memory where we need to write the new amount
            // Write the amount at that position
            mstore(add(add(_original, 32), _start), _amount)
        }

        return _original;
    }
}
