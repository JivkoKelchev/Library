const hre = require("hardhat");

const Library = require('../artifacts/contracts/Library.sol/Library.json')
const addBook = async function() {
    //TODO: pass provider url, wallet pk, contract address via parameters
    const provider = new hre.ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
    const wallet = new hre.ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);
    const balance = await wallet.getBalance();

    console.log(hre.ethers.utils.formatEther(balance, 18))
    const library = new hre.ethers.Contract("0x5FbDB2315678afecb367f032d93F642f64180aa3", Library.abi, wallet)
    await library.addBook("Test book 2", "test", 15);
    console.log('interaction finished');
}

addBook().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});