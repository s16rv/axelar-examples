// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SignatureVerifier {

    /**
     * @dev Verifies a given message hash was signed by the holder of the private key corresponding to the public key.
     * @param messageHash The hash of the message that was signed.
     * @param r The r value of the signature.
     * @param s The s value of the signature.
     * @param v The recovery id (27 or 28 usually).
     * @param expectedSigner The address expected to have signed the message.
     * @return Returns true if the signature is valid and was signed by the expected signer.
     */
    function verifySignature(
        bytes32 messageHash,
        bytes32 r,
        bytes32 s,
        uint8 v,
        address expectedSigner
    ) public pure returns (bool) {
        // Calculate the address that signed the message using ecrecover
        address signer = ecrecover(messageHash, v, r, s);
        
        // Check if the recovered address matches the expected signer address
        return signer == expectedSigner;
    }

    /**
     * @dev Helper function to recover signer address from signature.
     * @param messageHash The hash of the message that was signed.
     * @param r The r value of the signature.
     * @param s The s value of the signature.
     * @param v The recovery id (27 or 28 usually).
     * @return Returns the address that signed the message.
     */
    function recoverSigner(
        bytes32 messageHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address) {
        // Recover the signer's address from the message hash and signature
        return ecrecover(messageHash, v, r, s);
    }

    /**
     * @dev Helper function to hash a message. Uses Ethereum's prefixed hashing scheme.
     * @param message The message to hash.
     * @return The hash of the message in bytes32 format.
     */
    function getMessageHash(string memory message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(message));
    }

    /**
     * @dev Hashes and then recovers the signer from a message and signature.
     * @param message The original message that was signed.
     * @param r The r value of the signature.
     * @param s The s value of the signature.
     * @param v The recovery id (27 or 28 usually).
     * @return The address of the signer.
     */
    function verifyMessage(
        string memory message,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address) {
        // First, hash the message
        bytes32 messageHash = getMessageHash(message);

        // Recover the signer using the ecrecover function
        return ecrecover(messageHash, v, r, s);
    }
}
