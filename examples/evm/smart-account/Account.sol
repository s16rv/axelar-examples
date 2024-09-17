// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EntryPoint.sol";
import "./SignatureVerifier.sol";

contract Account is SignatureVerifier {
    address public owner;
    address private immutable _signer;
    EntryPoint private immutable _entryPoint;

    uint8 private constant SIGNATURE_V = 27;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event TransactionExecuted(address indexed dest, uint256 value, bytes data);

    constructor(
        address _owner,
        address _entryPointAddr,
        bytes32 _messageHash,
        bytes32 _r,
        bytes32 _s
    ) {
        owner = _owner;
        _entryPoint = EntryPoint(_entryPointAddr);
        _signer = recoverSigner(_messageHash, _r, _s, SIGNATURE_V);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    function getSigner() public view returns (address) {
        return _signer;
    }

    // Allow the owner to change the account owner
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    // Validate operation by checking the signature
    function validateOperation(bytes32 messageHash, bytes32 r, bytes32 s) external view returns (bool) {
        return verifySignature(messageHash, r, s, SIGNATURE_V, _signer);
    }

    // Allow the contract to execute arbitrary transactions
    function executeTransaction(address dest, uint256 value, bytes calldata data) external returns (bool) {
        _requireFromEntryPointOrOwner();
        bool success = _call(dest, value, data);
        emit TransactionExecuted(dest, value, data);
        return success;
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(_entryPoint) || msg.sender == owner, "account: not Owner or EntryPoint");
    }

    function _call(address target, uint256 value, bytes memory data) internal returns (bool) {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return success;
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
