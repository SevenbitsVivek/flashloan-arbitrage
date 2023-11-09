require("@nomiclabs/hardhat-waffle");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      { version: "0.6.6" },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://bsc-dataseed1.binance.org/",
        // url: "https://mainnet.infura.io/v3/7a6501efe07742e3af30a2f5e14d70de",
      },
    },
  },
};