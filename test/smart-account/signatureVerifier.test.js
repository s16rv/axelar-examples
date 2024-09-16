const { expect } = require("chai");
const { ethers } = require("hardhat");
const { hashMessage, splitSignature, arrayify, sha256 } = require('ethers/lib/utils');

const PUBKEY_A = "ApC+f+iGx0i+gOmLNA0UGNC/54ZWde5ZfZ2FBSZSAIXw"
const TX_BYTES_A_1 = "CoECCv4BCiUvaW50ZXJjaGFpbmF1dGguaWNhdXRoLnYxLk1zZ1N1Ym1pdFR4EtQBCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSCWNoYW5uZWwtMBqQAQocL2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZBJwCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSLWNvc21vczFtZ3A3cW52dW1obGNxNmU0ejJxMDVyMjlkY2hjeXVnMHozenhlZxoQCgV1YmV0YRIHMjAwMDAwMCCAoPHCsTQSWApQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohApC+f+iGx0i+gOmLNA0UGNC/54ZWde5ZfZ2FBSZSAIXwEgQKAggBGAESBBDAmgwaB2FscGhhLTE="
const TX_BYTES_A_2 = "CoECCv4BCiUvaW50ZXJjaGFpbmF1dGguaWNhdXRoLnYxLk1zZ1N1Ym1pdFR4EtQBCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSCWNoYW5uZWwtMBqQAQocL2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZBJwCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSLWNvc21vczFtZ3A3cW52dW1obGNxNmU0ejJxMDVyMjlkY2hjeXVnMHozenhlZxoQCgV1YmV0YRIHMjAwMDAwMCCAoPHCsTQSWApQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohApC+f+iGx0i+gOmLNA0UGNC/54ZWde5ZfZ2FBSZSAIXwEgQKAggBGAISBBDAmgwaB2FscGhhLTE="
const SIGNATURE_A_1 = "GHUe6rGUxcUuzLnjYJ8qE+qYoHkTjcKdr2c5Ea4mCJlzrMvDi6sZZCNO4K6taTiaeYmMgL+MNXBjMinM9fJKHg=="
const SIGNATURE_A_2 = "0A5QeQgokPkkOxxYgdw+shCF+3nwr1eq4fxhax+kQ+J3TycL0JpeF4CuSDyvnUHwGMQk4ecx/15cl9CzJtUbgw=="

const EXPECTED_SIGNER = "0x07557D755E777B85d878D34861cd52126524a155"

const TX_BYTES_B = "CoECCv4BCiUvaW50ZXJjaGFpbmF1dGguaWNhdXRoLnYxLk1zZ1N1Ym1pdFR4EtQBCi1jb3Ntb3MxcXFnc3J2cWFkeXc2azlqY2RnenRqY2RhcjlkY3A5bXd1eGtyODcSCWNoYW5uZWwtMBqQAQocL2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZBJwCi1jb3Ntb3MxcXFnc3J2cWFkeXc2azlqY2RnenRqY2RhcjlkY3A5bXd1eGtyODcSLWNvc21vczFtZ3A3cW52dW1obGNxNmU0ejJxMDVyMjlkY2hjeXVnMHozenhlZxoQCgV1YmV0YRIHMjAwMDAwMCCAoPHCsTQSWApQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohAhNuo/YyebxUDI/tjxHwhCfVVzaq8s4oWf0jSCggNcF/EgQKAggBGAcSBBDAmgwaB2FscGhhLTEgAQ=="
const SIGNATURE_B = "mgKX03kTOmC1E7TotpHUyAUbwfpF5bc5gqQGUdGGgVBYi9JX87Ha8Le4DViEirEPHcLe+s80hCl0aZlkrsOumg=="

describe("Signature Verifier Contracts", function () {
  let signatureVerifier;
  let owner;

  beforeEach(async function () {
    // Get accounts
    [owner] = await ethers.getSigners();

    // Deploy EntryPoint contract
    const SignatureVerifier = await ethers.getContractFactory("SignatureVerifier");
    signatureVerifier = await SignatureVerifier.deploy();
    await signatureVerifier.deployed();

    signatureVerifier.address
  });

  it("should recover signer A1", async function () {
    expect(signatureVerifier.address).to.be.string;

    const message = Buffer.from(TX_BYTES_A_1, 'base64');
    const signature = Buffer.from(SIGNATURE_A_1, 'base64');
    expect(signature.byteLength).to.equal(64);

    const r = '0x' + signature.subarray(0, 32).toString('hex');
    const s = '0x' + signature.subarray(32, 64).toString('hex');
    const v = 27; // or 28, depending on the signature

    const messageHash = sha256(message);
    expect(messageHash.length).to.equal(66);

    const address = await signatureVerifier.recoverSigner(messageHash, r, s, v);
    expect(address).to.equal(EXPECTED_SIGNER)

    const isValid = await signatureVerifier.verifySignature(messageHash, r, s, v, EXPECTED_SIGNER);
    expect(isValid).to.be.true;
  });

  it("should recover signer A2", async function () {
    expect(signatureVerifier.address).to.be.string;

    const message = Buffer.from(TX_BYTES_A_2, 'base64');
    const signature = Buffer.from(SIGNATURE_A_2, 'base64');
    expect(signature.byteLength).to.equal(64);

    const r = '0x' + signature.subarray(0, 32).toString('hex');
    const s = '0x' + signature.subarray(32, 64).toString('hex');
    const v = 27; // or 28, depending on the signature

    const messageHash = sha256(message);
    expect(messageHash.length).to.equal(66);

    const address = await signatureVerifier.recoverSigner(messageHash, r, s, v);
    expect(address).to.equal(EXPECTED_SIGNER)

    const isValid = await signatureVerifier.verifySignature(messageHash, r, s, v, EXPECTED_SIGNER);
    expect(isValid).to.be.true;
  });

  it("should not verify signature", async function () {
    expect(signatureVerifier.address).to.be.string;

    const message = Buffer.from(TX_BYTES_B, 'base64');
    const signature = Buffer.from(SIGNATURE_B, 'base64');
    expect(signature.byteLength).to.equal(64);

    const r = '0x' + signature.subarray(0, 32).toString('hex');
    const s = '0x' + signature.subarray(32, 64).toString('hex');
    const v = 27; // or 28, depending on the signature

    const messageHash = sha256(message);
    expect(messageHash.length).to.equal(66);

    const isValid = await signatureVerifier.verifySignature(messageHash, r, s, v, EXPECTED_SIGNER);
    expect(isValid).to.be.false;
  });

  it("should recover signer", async function () {
    const expectedSigner = owner.address

    const text = 0x512345673440
    const textBytes = arrayify(text)
    const messageHash = hashMessage(textBytes)
    const signature = await owner.signMessage(textBytes)
    const sig = splitSignature(signature)

    const address = await signatureVerifier.recoverSigner(messageHash, sig.r, sig.s, sig.v);
    expect(address).to.equal(expectedSigner, "first")

    const text2 = 0x56251512
    const textBytes2 = arrayify(text2)
    const messageHash2 = hashMessage(textBytes2)
    const signature2 = await owner.signMessage(textBytes2)
    const sig2 = splitSignature(signature2)

    const address2 = await signatureVerifier.recoverSigner(messageHash2, sig2.r, sig2.s, sig2.v);
    expect(address2).to.equal(expectedSigner, "second")
  })
})