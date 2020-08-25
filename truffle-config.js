const TruffleConfig = require('@aragon/truffle-config-v5/truffle-config')

// See <http://truffleframework.com/docs/advanced/configuration>
// to customize your Truffle configuration!

TruffleConfig.networks.development = {
    host: 'localhost',
    port: 9545,
    network_id: '*',
    gas: 8000000,
    gasPrice: 1000000000, // web3.eth.gasPrice
};

TruffleConfig.networks.rinkeby.skipDryRun = true;
TruffleConfig.networks.rinkeby.gasPrice = 1e11; // 100 Gwei

TruffleConfig.networks.mainnet.gasPrice = 1e11; // 100 Gwei

TruffleConfig.compilers = {
    solc: {
        version: '0.5.12',
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            }
        }
    }
};

TruffleConfig.mocha = { // https://github.com/cgewecke/eth-gas-reporter
    reporter: 'eth-gas-reporter',
    reporterOptions : {
        currency: 'USD',
        gasPrice: 10,
        onlyCalledMethods: true,
        showTimeSpent: true,
        excludeContracts: ['Migrations']
    }
};

TruffleConfig.plugins = ['solidity-coverage', 'truffle-plugin-verify'];

TruffleConfig.api_keys = {
    etherscan: process.env.ETHERSCAN_API_KEY
};

module.exports = TruffleConfig;

