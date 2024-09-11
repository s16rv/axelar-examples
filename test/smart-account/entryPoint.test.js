const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = require('ethers/lib/utils');
const { ecsign } = require('ethereumjs-util');
const { Account } = require("@multiversx/sdk-core/out");

describe("EntryPoint and Account Contracts", function () {
  let entryPoint;
  let account;
  let owner;
  let user;

  beforeEach(async function () {
    // Get accounts
    [owner, user] = await ethers.getSigners();

    // Deploy EntryPoint contract
    const EntryPoint = await ethers.getContractFactory("EntryPoint");
    entryPoint = await EntryPoint.deploy();
    await entryPoint.deployed();

    // Call EntryPoint to create a new account
    const newAccountTx = await entryPoint.createAccount(user.address);
    const txReceipt = await newAccountTx.wait();

    // Get the new account address from emitted events
    const newAccountAddress = txReceipt.events[0].args.accountAddress;
    
    // Check if the new account was deployed correctly
    account = await ethers.getContractAt("Account", newAccountAddress);
  });

  it("should create a new account and assign the correct owner", async function () {
    expect(await account.owner()).to.equal(user.address);
  });

//   it("should validate the user operation signature correctly", async function () {
//     // Create a sample user operation (sending a transaction)
//     const target = owner.address;
//     const value = ethers.utils.parseEther("1");
//     const data = "0x";
    
//     // Create userOpHash
//     const userOpHash = keccak256(
//       defaultAbiCoder.encode(
//         ["address", "address", "uint256", "bytes"],
//         [account.address, target, value, data]
//       )
//     );

//     // Sign the userOpHash
//     const messageHashBytes = Buffer.from(userOpHash.slice(2), "hex");
//     const privateKey = Buffer.from(user.privateKey.slice(2), "hex");
//     const { r, s, v } = ecsign(messageHashBytes, privateKey);

//     // Prepare the signature
//     const signature = solidityPack(["bytes32", "bytes32", "uint8"], [r, s, v]);

//     // Handle the transaction via EntryPoint
//     await expect(
//       entryPoint.handleTransaction(account.address, target, value, data, signature)
//     ).to.be.revertedWith("Invalid signature");
//   });
});

// describe("EntryPointWithoutSignature and Account Contracts", function () {
//     let entryPoint;
//     let account;
//     let owner;
//     let user;
  
//     beforeEach(async function () {
//       // Get accounts
//       [owner, user] = await ethers.getSigners();
  
//       // Deploy EntryPoint contract
//       const EntryPoint = await ethers.getContractFactory("EntryPointWithoutSignature");
//       entryPoint = await EntryPoint.deploy();
//       await entryPoint.deployed();
  
//       // Call EntryPoint to create a new account
//       const newAccountTx = await entryPoint.createAccount(user.address);
//       const txReceipt = await newAccountTx.wait();
  
//       // Get the new account address from emitted events
//       const newAccountAddress = txReceipt.events[0].args.accountAddress;
      
//       // Check if the new account was deployed correctly
//       account = await ethers.getContractAt("Account", newAccountAddress);
//     });
  
//     it("should create a new account and assign the correct owner", async function () {
//       expect(await account.owner()).to.equal(user.address);
//     });
  
//     it("should handle transaction correctly", async function () {
//       // Create a sample user operation (sending a transaction)
//       const target = owner.address;
//       const value = ethers.utils.parseEther("1");
//       const data = "0x";
  
//       // Handle the transaction via EntryPoint
//       await expect(
//         entryPoint.handleTransaction(account.address, target, value, data)
//       ).to.be.revertedWith("Transaction failed");

//       // Send balance to account contract
//       const amountToSend = ethers.utils.parseEther("2.0"); // 2 Ether

//       // Send funds to the recipient account
//       await expect(() => owner.sendTransaction({
//         to: account.address,
//         value: amountToSend,
//       })).to.changeEtherBalance(account, amountToSend);

//       // Verify that the recipient account balance is updated correctly
//       expect(await ethers.provider.getBalance(account.address)).to.equal(amountToSend);

//       // Handle the transaction via EntryPoint
//       const handleTx = await entryPoint.handleTransaction(account.address, target, value, data);
//       const txReceipt = await handleTx.wait();
//       expect(
//         txReceipt
//       ).to.be.equal(true);
//     });
//   });
  
describe("EntryPointWithoutSignature and Account Contracts", function () {
  let entryPoint;
  let account;
  let owner;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    const MockGateway = await ethers.getContractFactory("MockGateway");
    const mockGateway = await MockGateway.deploy();

    // Deploy EntryPointWithoutSignature contract
    const EntryPointWithoutSignature = await ethers.getContractFactory("EntryPointWithoutSignature");
    entryPoint = await EntryPointWithoutSignature.deploy(mockGateway.address, "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6");
    await entryPoint.deployed();

    const commandId = ethers.utils.formatBytes32String("commandId");
    const sourceChain = "sourceChain";
    const sourceAddress = user.address;
    const payload = ethers.utils.defaultAbiCoder.encode(
      ["uint8", "address"],
      [1, owner.address],
    );

    await mockGateway.setCallValid(true);
    const tx = await entryPoint.execute(commandId, sourceChain, sourceAddress, payload);
    const receipt = await tx.wait();
    const event = receipt.events.find((e) => e.event === "AccountCreated");
    account = await ethers.getContractAt("AccountWithoutSignature", event.args[0]);

    await owner.sendTransaction({
      to: account.address,
      value: ethers.utils.parseEther("2.0"),
    });
  });

  it("should have funds", async function () {
    expect(await ethers.provider.getBalance(account.address)).to.gt(0);
  });

  it("should execute transactions from Account contract", async function () {
    const initialOwnerBalance = await ethers.provider.getBalance(user.address);
    const amountToSend = ethers.utils.parseEther("1.0");

    const data = account.interface.encodeFunctionData("executeTransaction", [user.address, amountToSend, "0x"]);

    // Execute transaction from the Account contract
    const commandId = ethers.utils.formatBytes32String("commandId");
    const sourceChain = "sourceChain";
    const sourceAddress = "sourceAddress";
    const payload = ethers.utils.defaultAbiCoder.encode(
      ["uint8", "address", "bytes"],
      [2, account.address, data],
    );
    console.log("Payload :", payload)
    await entryPoint.execute(commandId, sourceChain, sourceAddress, payload);

    // Verify that the owner received the Ether
    expect(await ethers.provider.getBalance(user.address)).to.equal(initialOwnerBalance.add(amountToSend));
  });
});