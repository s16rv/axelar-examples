const { ethers } = require('ethers');

const provider = new ethers.providers.JsonRpcProvider('https://ethereum-sepolia-rpc.publicnode.com');

const accountjson = require('../artifacts/examples/evm/smart-account/Account.sol/Account.json')
const contractAddressAccount = '0xaecaa6210e3e3aa66e0753b24e61b97f7b045d7d';

const contractAccount = new ethers.Contract(contractAddressAccount, accountjson.abi, provider);

async function queryFunction() {
    try {
        console.log("Address :", contractAccount.address)
        const signer = await contractAccount.getSigner();
        console.log("Signer :", signer);
        const owner = await contractAccount.owner();
        console.log("Owner :", owner);
        const result = await contractAccount.validateOperation(
            "0xa268eead559ee12b6aff00a72a51a81d4a7007168f84e6780f750e02d7882b33",
            "0x18751eeab194c5c52eccb9e3609f2a13ea98a079138dc29daf673911ae260899",
            "0x73accbc38bab1964234ee0aead69389a79898c80bf8c3570633229ccf5f24a1e"
        );
        console.log("validateOperation :", result);
    } catch (error) {
        console.error('Error querying contract:', error);
    }
}

// Execute the query
queryFunction();
