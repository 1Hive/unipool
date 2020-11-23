const UnipoolFactory = artifacts.require('./UnipoolFactory.sol');
const Unipool = artifacts.require('./Unipool.sol');
const UnipoolMock = artifacts.require('./UnipoolMock.sol');
const HoneyTokenMock = artifacts.require('./HoneyTokenMock.sol');
const HoneyTokenActual = '0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9';
const OtherTokenMock = artifacts.require('./UniswapTokenMock.sol');
const UniswapPairMock = artifacts.require('./UniswapPairMock.sol');
const UniswapRouterMock = artifacts.require('./UniswapRouterMock.sol');

const argValue = (arg, defaultValue) => process.argv.includes(arg) ? process.argv[process.argv.indexOf(arg) + 1] : defaultValue;
const network = () => argValue('--network', 'local');

module.exports = async function (deployer) {
    if (network() === 'xdai') {
        await deployer.deploy(UnipoolFactory, HoneyTokenActual);
    } else {
        const senderAccount = (await web3.eth.getAccounts())[0];
        const BN = web3.utils.toBN;

        await deployer.deploy(HoneyTokenMock, senderAccount);
        await deployer.deploy(OtherTokenMock);
        await deployer.deploy(UniswapPairMock, HoneyTokenMock.address, OtherTokenMock.address);

        const uniswapToken = await UniswapPairMock.at(UniswapPairMock.address);
        await uniswapToken.mint(senderAccount, BN(1000).mul(BN(10).pow(BN(18))));

        await deployer.deploy(UniswapRouterMock);

        await deployer.deploy(UnipoolMock, uniswapToken.address, HoneyTokenMock.address, UniswapRouterMock.address);
    }
};
