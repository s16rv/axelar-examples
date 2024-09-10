// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccountWithoutSignature {
    address public owner;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event TransactionExecuted(address indexed target, uint256 value, bytes data);
    event FundSent(address indexed receiver, uint amount);

    constructor(address _owner) {
        owner = _owner;
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
    function executeTransaction(address target, uint256 value, bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        require(success, "Transaction failed");
        emit TransactionExecuted(target, value, data);
        return returnData;
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
