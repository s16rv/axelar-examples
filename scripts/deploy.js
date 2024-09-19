// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const chain = {
        gateway: "0xe432150cce91c13a887f7D836923d5597adD8E31",
        gasService: "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6"
    };
  
    // Compile the contract and get the contract factory
    const EntryPoint = await ethers.getContractFactory("EntryPoint");
    
    // Deploy the contract and pass constructor arguments
    const contract = await EntryPoint.deploy(chain.gateway, chain.gasService);
  
    console.log("Contract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  