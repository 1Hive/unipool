const TruffleConfig = require("@aragon/truffle-config-v5/truffle-config");
const HDWalletProvider = require("@truffle/hdwallet-provider");

// See <http://truffleframework.com/docs/advanced/configuration>
// to customize your Truffle configuration!

// TruffleConfig.networks.development = {
//   host: "localhost",
//   port: 9545,
//   network_id: "*",
//   gas: 8000000,
//   gasPrice: 1000000000, // web3.eth.gasPrice
// };

require("dotenv").config();

TruffleConfig.networks.xdai = {
  provider: function () {
    return new HDWalletProvider(
      process.env.MNEMONIC,
      "https://dai.poa.network"
    );
  },
  network_id: 100,
  gas: 2000000,
};

TruffleConfig.networks.goerli = {
  provider: function () {
    return new HDWalletProvider(
      process.env.MNEMONIC,
      `https://goerli.infura.io/v3/${process.env.INFURA_GOERLI}`
    );
  },
  network_id: 5,
  gas: 2000000,
};

TruffleConfig.networks.goerli.skipDryRun = true;
TruffleConfig.networks.goerli.gasPrice = 1e11; // 100 Gwei

TruffleConfig.networks.rinkeby.skipDryRun = true;
TruffleConfig.networks.rinkeby.gasPrice = 1e11; // 100 Gwei

// UPDATE TO AN ACCEPTABLE GAS PRICE
TruffleConfig.networks.mainnet.gasPrice = 1e11; // 100 Gwei

TruffleConfig.compilers = {
  solc: {
    version: "0.5.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};

TruffleConfig.mocha = {
  // https://github.com/cgewecke/eth-gas-reporter
  reporter: "eth-gas-reporter",
  reporterOptions: {
    currency: "USD",
    gasPrice: 10,
    onlyCalledMethods: true,
    showTimeSpent: true,
    excludeContracts: ["Migrations"],
  },
};

TruffleConfig.plugins = ["truffle-plugin-verify"];

TruffleConfig.api_keys = {
  etherscan: process.env.ETHERSCAN_API_KEY,
};

module.exports = TruffleConfig;
