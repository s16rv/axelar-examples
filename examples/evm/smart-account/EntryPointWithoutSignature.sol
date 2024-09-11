// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import "./AccountWithoutSignature.sol";

contract EntryPointWithoutSignature is AxelarExecutable {
    IAxelarGasService public immutable gasService;

    event Executed(string sourceChain, string sourceAddress);
    event TransactionExecuted(address indexed target, bytes data);
    event AccountCreated(address indexed accountAddress, address indexed owner);

    /**
     *
     * @param _gateway address of axl gateway on deployed chain
     * @param _gasReceiver address of axl gas service on deployed chain
     */
    constructor(address _gateway, address _gasReceiver) AxelarExecutable(_gateway) {
        gasService = IAxelarGasService(_gasReceiver);
    }

    /**
     * @notice Send message from chain A to chain B
     * @dev message param is passed in as gmp message
     * @param destinationChain name of the dest chain (ex. "Fantom")
     * @param destinationAddress address on dest chain this tx is going to
     * @param _message message to be sent
     */
    function setRemoteValue(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata _message
    ) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(_message);
        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /**
     * @notice logic to be executed on dest chain
     * @dev this is triggered automatically by relayer
     * @param _sourceChain blockchain where tx is originating from
     * @param _sourceAddress address on src chain where tx is originating from
     * @param _payload encoded gmp message sent from src chain
     */
    function _execute(string calldata _sourceChain, string calldata _sourceAddress, bytes calldata _payload) internal override {
        // Decode the first part of the payload to identify which function to execute
        (uint8 category) = abi.decode(_payload[:32], (uint8));

        if (category == 1) {
            // Handle category 2: createAccount
            (address owner) = abi.decode(_payload[32:], (address));
            
            createAccount(owner);
        } 
        else if (category == 2) {
            // Handle category 2: handleTransaction
            // Check that the payload is large enough to contain both an address and the data
            require(_payload.length > 32 + 20, "Payload too short");

            // Decode the address first
            address target = abi.decode(_payload[32:64], (address));

            // Decode the rest as bytes
            bytes calldata data = _payload[128:];
            handleTransaction(target, data);
        } 
        else {
            revert("Unsupported category");
        }

        // Emit the executed event
        emit Executed(_sourceChain, _sourceAddress);
    }

    function handleTransaction(
        address target,
        bytes calldata data
    ) public {
        (bool success, ) = target.call(data);
        require(success, "Transaction failed");

        emit TransactionExecuted(target, data);
    }

    function createAccount(address owner) public returns (address) {
        AccountWithoutSignature newAccount = new AccountWithoutSignature(owner, address(this));
        emit AccountCreated(address(newAccount), owner);
        return address(newAccount);
    }
}
