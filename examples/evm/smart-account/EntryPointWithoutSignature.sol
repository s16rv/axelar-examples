// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Account.sol";

contract EntryPointWithoutSignature {
    event TransactionExecuted(address indexed target, uint256 value, bytes data);
    event AccountCreated(address indexed accountAddress, address indexed owner);

    function handleTransaction(
        address target,
        uint256 value,
        bytes memory data
    ) public payable {
        (bool success, ) = target.call{value: value}(data);
        require(success, "Transaction failed");

        emit TransactionExecuted(target, value, data);
    }

    function createAccount(address owner) public returns (address) {
        Account newAccount = new Account(owner);
        emit AccountCreated(address(newAccount), owner);
        return address(newAccount);
    }
}
