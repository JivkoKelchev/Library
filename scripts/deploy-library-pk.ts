import {ethers} from "hardhat";

export async function main(_privateKey: string) {
    console.log(_privateKey);
    const wallet = new ethers.Wallet(_privateKey, ethers.provider); // New wallet with the privateKey passed from CLI as param
    console.log("Deploying contracts with the account:", wallet.address); // We are printing the address of the deployer
    const LibraryFactory = await ethers.getContractFactory("Library");
    const library = await LibraryFactory.connect(wallet).deploy();
    await library.deployed();
    console.log(`The Library contract is deployed to ${library.address}`);
    const owner = await library.owner();
    console.log(`The Library contract owner is ${owner}`);
}