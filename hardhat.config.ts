import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import { HardhatUserConfig, task, subtask } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      chainId: 5,
      accounts: [
        `${process.env.PRIVATE_KEY}`,
      ],
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      chainId: 11155111,
      accounts: [
        `${process.env.PRIVATE_KEY}`,
      ],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  },
};

const lazyImport = async (module: any) => {
  return await import(module);
};

task("deploy-library", "Deploys contracts").setAction(async () => {
  const { main } = await lazyImport("./scripts/deploy-library");
  await main();
});

task("deploy-library-pk", "Deploys contract with pk")
    .addParam("privateKey", "Please provide the private key")
    .setAction(async ({ privateKey }) => {
      const { main } = await lazyImport("./scripts/deploy-library-pk");
      await main(privateKey);
    });

task("deploy-library-sepolia", "Deploys contract on sepolia")
    .setAction(async ({ privateKey }) => {
      const { main } = await lazyImport("./scripts/deploy-library-sepolia");
      await main(privateKey);
    });

task("deploy-library-goerli", "Deploys contract on goerli")
    .setAction(async ({ privateKey }) => {
        const { main } = await lazyImport("./scripts/deploy-library-goerli");
        await main(privateKey);
    });

subtask("print", "Prints a message")
    .addParam("message", "The message to print")
    .setAction(async (taskArgs) => {
      console.log(taskArgs.message);
    });

export default config;
