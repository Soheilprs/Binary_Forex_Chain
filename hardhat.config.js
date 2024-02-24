require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });

// const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
// const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const BSC_RPC_URL = process.env.BSC_RPC_URL;
const BSCSCAN_API_KEY = process.env.BSCSCAN_API_KEY;

module.exports = {
  solidity: "0.8.20",
  networks: {
    bsc: {
      url: BSC_RPC_URL,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: BSCSCAN_API_KEY,
  },
};
