// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntryPointWithoutSignature.sol";

contract AccountWithoutSignature {
    address public owner;
    EntryPointWithoutSignature private immutable _entryPoint;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event TransactionExecuted(address indexed dest, uint256 value, bytes data);

    constructor(address _owner, EntryPointWithoutSignature _entryPointAddr) {
        owner = _owner;
        _entryPoint = _entryPointAddr;
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    // Allow the owner to change the account owner
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    // Allow the contract to execute arbitrary transactions
    function executeTransaction(address dest, uint256 value, bytes calldata data) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, data);
        emit TransactionExecuted(dest, value, data);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(_entryPoint) || msg.sender == owner, "account: not Owner or EntryPoint");
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
