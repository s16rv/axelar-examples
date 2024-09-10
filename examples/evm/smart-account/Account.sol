// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Account {
    address public owner;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Allow the owner to change the account owner
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    // Validate user operation by checking the signature
    function validateUserOp(bytes32 userOpHash, bytes memory signature) public view returns (bool) {
        // Recover the signer address from the hash and signature
        address signer = recoverSigner(userOpHash, signature);
        return signer == owner;
    }

    // ECDSA Signature recovery function
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the signature parameters
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Version of signature should be 27 or 28
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature version");

        // Recover the signer
        return ecrecover(hash, v, r, s);
    }

    // Allow owner to execute arbitrary transactions
    function executeTransaction(address target, uint256 value, bytes memory data) public onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        require(success, "Transaction failed");
        return returnData;
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
