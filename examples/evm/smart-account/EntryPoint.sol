// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Account.sol";

interface IAccount {
    function validateUserOp(bytes32 userOpHash, bytes memory signature) external view returns (bool);
}

contract EntryPoint {
    event TransactionExecuted(address indexed account, address indexed target, uint256 value, bytes data);
    event AccountCreated(address indexed accountAddress, address indexed owner);

    function handleTransaction(
        address account,
        address target,
        uint256 value,
        bytes memory data,
        bytes memory signature
    ) public payable {
        // Create a user operation hash for validation
        bytes32 userOpHash = keccak256(abi.encodePacked(account, target, value, data));

        // Verify the user's signature
        require(IAccount(account).validateUserOp(userOpHash, signature), "Invalid signature");

        // Execute the transaction
        (bool success, ) = target.call{value: value}(data);
        require(success, "Transaction failed");

        emit TransactionExecuted(account, target, value, data);
    }

    function createAccount(address owner) public returns (address) {
        Account newAccount = new Account(owner);
        emit AccountCreated(address(newAccount), owner);
        return address(newAccount);
    }
}
