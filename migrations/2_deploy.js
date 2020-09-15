const UnipoolFactory = artifacts.require('./UnipoolFactory.sol');

const argValue = (arg, defaultValue) => process.argv.includes(arg) ? process.argv[process.argv.indexOf(arg) + 1] : defaultValue;
const network = () => argValue('--network', 'local');

module.exports = async function (deployer) {
    if (network() === 'xdai') {
        await deployer.deploy(UnipoolFactory);
    } else {
        throw new Error('Unsupported network.')
    }
};
