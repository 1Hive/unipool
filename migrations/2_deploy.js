const Unipool = artifacts.require('./Unipool.sol');

module.exports = async function (deployer) {
    await deployer.deploy(Unipool);
};
