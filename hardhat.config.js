require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-contract-sizer");

/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();

const AURORA_PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.9",
  settings: {
    optimizer: {
      enabled: true,
      runs: 900,
    },
  },
  networks: {
    // testnet_aurora: {
    //   url: "https://testnet.aurora.dev",
    //   accounts: [`0x${AURORA_PRIVATE_KEY}`],
    //   chainId: 1313161555,
    //   gasPrice: 100 * 1000000000,
    // },
    // local_aurora: {
    //   url: "http://localhost:8545",
    //   accounts: [`0x${AURORA_PRIVATE_KEY}`],
    //   chainId: 1313161555,
    //   gasPrice: 120 * 1000000000,
    // },
    rinkeby: {
      url: "https://rpc.ankr.com/eth_rinkeby",
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 4,
      gasPrice: 30 * 1000000000,
    },
    ropsten: {
      url: "https://rpc.ankr.com/eth_ropsten",
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 3,
      gasPrice: 30 * 1000000000,
    },
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/07f81ed71ca9494aaca81309bfc84bfd",
      accounts: [`0x${AURORA_PRIVATE_KEY}`],
      chainId: 80001,
      gasPrice: 50 * 1000000000,
    },
  },
};
