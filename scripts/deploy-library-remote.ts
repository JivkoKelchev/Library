import { ethers, config } from "hardhat";
import { HttpNetworkConfig} from "hardhat/types";

export async function main(networkName: string) {
    //read configurations
    const networkConfig = config.networks;
    const desiredNetwork = networkConfig[networkName];
    const {url, accounts} = desiredNetwork as HttpNetworkConfig;
    const provider = new ethers.providers.JsonRpcProvider(url);
    const signer = new ethers.Wallet((accounts as string[])[0], provider);
    const networkInfo = await provider.getNetwork();
    //deploy
    console.log("Deploying to network:", networkInfo.name);
    console.log("Deploying contracts with the account:", signer.address);
    const LibraryFactory = await ethers.getContractFactory("Library");
    const library = await LibraryFactory.connect(signer).deploy();
    await library.deployed();
    console.log(`The Library contract is deployed to ${library.address}`);
    const owner = await library.owner();
    console.log(`The Library contract owner is ${owner}`);
}