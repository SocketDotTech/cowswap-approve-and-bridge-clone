// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {ISocketGateway} from "./interface/ISocketGateway.sol";
import {ApproveAndBridge, IERC20} from "./mixin/ApproveAndBridge.sol";

/// ! @dev UNAUDITED UNTESTED Do not use in production
/// @dev Performs two steps before bridging:
/// 1. Modify input amount in calldata
/// 2. Modify output amount in calldata
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
        uint256 extraDataLength = 32 * 3;
        if (data.length < 4 + extraDataLength) revert InvalidInput();
        bytes memory routeExecutionCalldata = data[4:data.length - extraDataLength];

        // 2. Decode the extra data struct
        bytes memory extraData = data[data.length - 32 * 4:];
        (uint256 inputAmountStartIndex, bool modifyOutputAmount, uint256 outputAmountStartIndex) =
            abi.decode(extraData, (uint256, bool, uint256));

        // 4. Replace input amount in calldata
        bytes memory modifiedCalldata =
            _replaceUint256({_original: routeExecutionCalldata, _start: inputAmountStartIndex, _amount: amount});

        // 5. If needed, also replace output amount
        // in case of bridges like Across, need to modify both input and output amounts
        // - decode current input and output amounts from calldata
        // - calculate and apply the percentage diff bw new and old input amount on the old output amount
        // - replace the output amount at the index with the new amount
        // - assumes output amount is always uint256 in SocketGateway impls
        if (modifyOutputAmount) {
            uint256 inputAmountOriginal = _readUint256({_data: routeExecutionCalldata, _index: inputAmountStartIndex});
            uint256 outputAmountOriginal = _readUint256({_data: routeExecutionCalldata, _index: outputAmountStartIndex});
            uint256 newOutputAmount =
                _applyPctDiff({_base: inputAmountOriginal, _compare: amount, _target: outputAmountOriginal});
            modifiedCalldata =
                _replaceUint256({_original: modifiedCalldata, _start: outputAmountStartIndex, _amount: newOutputAmount});
        }

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

    /// @notice Calculates positive percentage difference between two numbers and applies it to a third number
    /// @param _base The base number to compare against
    /// @param _compare The number to compare with the base (should be >= _base)
    /// @param _target The number to apply the percentage difference to
    /// @return The target number adjusted by the percentage difference
    function _addPctDiff(uint256 _base, uint256 _compare, uint256 _target) internal pure returns (uint256) {
        // Base number must be greater than 0
        // Compare number must be greater than or equal to base number
        if (_base <= 0 || _compare < _base) revert InvalidInput();

        // Calculate the percentage difference
        uint256 difference = ((_compare - _base) * 1e18) / _base;
        // Apply percentage increase
        return _target + ((_target * difference) / 1e18);
    }

    /// @notice Calculates negative percentage difference between two numbers and applies it to a third number
    /// @param _base The base number to compare against
    /// @param _compare The number to compare with the base (should be >= _base)
    /// @param _target The number to apply the percentage difference to
    /// @return The target number adjusted by the percentage difference
    function _subPctDiff(uint256 _base, uint256 _compare, uint256 _target) internal pure returns (uint256) {
        // Base number must be greater than 0
        // Compare number must be less than or equal to base number
        if (_base <= 0 || _compare > _base) revert InvalidInput();

        // Calculate the percentage difference
        uint256 difference = ((_base - _compare) * 1e18) / _base;
        // Apply percentage decrease
        return _target - ((_target * difference) / 1e18);
    }

    function _applyPctDiff(uint256 _base, uint256 _compare, uint256 _target) internal pure returns (uint256) {
        if (_compare > _base) {
            return _addPctDiff(_base, _compare, _target);
        } else {
            return _subPctDiff(_base, _compare, _target);
        }
    }

    // Helper to read a uint256 at a given byte index in a bytes array
    function _readUint256(bytes memory _data, uint256 _index) internal pure returns (uint256 value) {
        if (_data.length < _index + 32) revert PositionOutOfBounds();
        assembly {
            value := mload(add(add(_data, 0x20), _index))
        }
    }
}
