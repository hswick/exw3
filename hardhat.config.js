
require("@nomiclabs/hardhat-waffle");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    ganache: {
      url: "http://127.0.0.1:8545",
      saveDeployments: true
    },
  },
  solidity: "0.8.0",
  paths: {
    sources: "./test/examples/contracts",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};
