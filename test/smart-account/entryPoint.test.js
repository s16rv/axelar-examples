const { expect } = require("chai");
const { ethers } = require("hardhat");
const { sha256 } = require('ethers/lib/utils');

const TX_BYTES_A_1 = "CoECCv4BCiUvaW50ZXJjaGFpbmF1dGguaWNhdXRoLnYxLk1zZ1N1Ym1pdFR4EtQBCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSCWNoYW5uZWwtMBqQAQocL2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZBJwCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSLWNvc21vczFtZ3A3cW52dW1obGNxNmU0ejJxMDVyMjlkY2hjeXVnMHozenhlZxoQCgV1YmV0YRIHMjAwMDAwMCCAoPHCsTQSWApQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohApC+f+iGx0i+gOmLNA0UGNC/54ZWde5ZfZ2FBSZSAIXwEgQKAggBGAESBBDAmgwaB2FscGhhLTE="
const TX_BYTES_A_2 = "CoECCv4BCiUvaW50ZXJjaGFpbmF1dGguaWNhdXRoLnYxLk1zZ1N1Ym1pdFR4EtQBCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSCWNoYW5uZWwtMBqQAQocL2Nvc21vcy5iYW5rLnYxYmV0YTEuTXNnU2VuZBJwCi1jb3Ntb3MxenlwcWE3NmplN3B4c2R3a2ZhaDZtdTlhNTgzc2p1NnhxdDNtdjYSLWNvc21vczFtZ3A3cW52dW1obGNxNmU0ejJxMDVyMjlkY2hjeXVnMHozenhlZxoQCgV1YmV0YRIHMjAwMDAwMCCAoPHCsTQSWApQCkYKHy9jb3Ntb3MuY3J5cHRvLnNlY3AyNTZrMS5QdWJLZXkSIwohApC+f+iGx0i+gOmLNA0UGNC/54ZWde5ZfZ2FBSZSAIXwEgQKAggBGAISBBDAmgwaB2FscGhhLTE="
const SIGNATURE_A_1 = "GHUe6rGUxcUuzLnjYJ8qE+qYoHkTjcKdr2c5Ea4mCJlzrMvDi6sZZCNO4K6taTiaeYmMgL+MNXBjMinM9fJKHg=="
const SIGNATURE_A_2 = "0A5QeQgokPkkOxxYgdw+shCF+3nwr1eq4fxhax+kQ+J3TycL0JpeF4CuSDyvnUHwGMQk4ecx/15cl9CzJtUbgw=="

const EXPECTED_SIGNER = "0x07557D755E777B85d878D34861cd52126524a155"
  
describe("EntryPoint and Account Contracts", function () {
  let entryPoint;
  let account;
  let owner;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    const MockGateway = await ethers.getContractFactory("MockGateway");
    const mockGateway = await MockGateway.deploy();

    // Deploy EntryPoint contract
    const EntryPoint = await ethers.getContractFactory("EntryPoint");
    entryPoint = await EntryPoint.deploy(mockGateway.address, "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6");
    await entryPoint.deployed();

    const commandId = ethers.utils.formatBytes32String("commandId");
    const sourceChain = "sourceChain";
    const sourceAddress = user.address;

    const message = Buffer.from(TX_BYTES_A_1, 'base64');
    const signature = Buffer.from(SIGNATURE_A_1, 'base64');

    const r = '0x' + signature.subarray(0, 32).toString('hex');
    const s = '0x' + signature.subarray(32, 64).toString('hex');

    const messageHash = sha256(message);

    const payload = ethers.utils.defaultAbiCoder.encode(
      ["uint8", "address", "bytes32", "bytes32", "bytes32"],
      [1, owner.address, messageHash, r, s],
    );

    await mockGateway.setCallValid(true);
    const tx = await entryPoint.execute(commandId, sourceChain, sourceAddress, payload);
    const receipt = await tx.wait();
    const event = receipt.events.find((e) => e.event === "AccountCreated");
    account = await ethers.getContractAt("Account", event.args[0]);

    await owner.sendTransaction({
      to: account.address,
      value: ethers.utils.parseEther("2.0"),
    });
  });

  it("should have funds", async function () {
    expect(await ethers.provider.getBalance(account.address)).to.gt(0);
  });

  it("should have signer", async function () {
    expect(await account.getSigner()).to.equal(EXPECTED_SIGNER);
  });

  it("should execute transactions from Account contract", async function () {
    const recipient = user.address;
    const initialOwnerBalance = await ethers.provider.getBalance(recipient);
    const amountToSend = ethers.utils.parseEther("0.001");

    // Execute transaction from the Account contract
    const commandId = ethers.utils.formatBytes32String("commandId");
    const sourceChain = "sourceChain";
    const sourceAddress = user.address;

    const message = Buffer.from(TX_BYTES_A_1, 'base64');
    const signature = Buffer.from(SIGNATURE_A_1, 'base64');

    const r = '0x' + signature.subarray(0, 32).toString('hex');
    const s = '0x' + signature.subarray(32, 64).toString('hex');

    const messageHash = sha256(message);

    const payload = ethers.utils.defaultAbiCoder.encode(
      ["uint8", "address", "bytes32", "bytes32", "bytes32", "address", "uint256", "bytes"],
      [2, account.address, messageHash, r, s, recipient, amountToSend, "0x"],
    );
    await entryPoint.execute(commandId, sourceChain, sourceAddress, payload);

    // Verify that the owner received the Ether
    expect(await ethers.provider.getBalance(recipient)).to.equal(initialOwnerBalance.add(amountToSend));
  });
});