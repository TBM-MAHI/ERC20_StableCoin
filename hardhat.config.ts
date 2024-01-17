import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        },
      },
    },
  },
  networks: {
    sepolia: {
      url: process.env.INFURA_NODE_URL,
      accounts: [process.env.PRIVATE_KEY as string],
    },
  },
  etherscan: {
    apiKey: process.env.API_KEY,
  },
  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: true,
  },
};

export default config;
