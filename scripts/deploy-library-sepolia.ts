import {ethers, config} from "hardhat";

export async function main() {
    const networkName = 'sepolia';
    const networkConfig = config.networks;
    const desiredNetwork = networkConfig[networkName];
    const {url, accounts} = desiredNetwork;
    const provider = new ethers.providers.JsonRpcProvider(url);
    const signer = new ethers.Wallet(accounts[0], provider);
    const networkInfo = await provider.getNetwork();
    console.log("Deploying to network:", networkInfo.name);
  
    console.log("Deploying contracts with the account:", signer.address); // We are printing the address of the deployer

    const LibraryFactory = await ethers.getContractFactory("Library");
    const library = await LibraryFactory.connect(signer).deploy();
    await library.deployed();
    console.log(`The Library contract is deployed to ${library.address}`);
    const owner = await library.owner();
    console.log(`The Library contract owner is ${owner}`);
}