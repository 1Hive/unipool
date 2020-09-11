const Unipool = artifacts.require('./Unipool.sol');
const UnipoolMock = artifacts.require('./UnipoolMock.sol');
const UltraTokenMock = artifacts.require('./UltraTokenMock.sol');
const UniswapTokenMock = artifacts.require('./UniswapTokenMock.sol');

const argValue = (arg, defaultValue) => process.argv.includes(arg) ? process.argv[process.argv.indexOf(arg) + 1] : defaultValue;
const network = () => argValue('--network', 'local');

module.exports = async function (deployer) {
    if (network() === 'mainnet') {
        await deployer.deploy(Unipool);
    } else {
        const senderAccount = (await web3.eth.getAccounts())[0];
        const BN = web3.utils.toBN;

        await deployer.deploy(UltraTokenMock, senderAccount);

        await deployer.deploy(UniswapTokenMock);
        const uniswapToken = await UniswapTokenMock.at(UniswapTokenMock.address);
        await uniswapToken.mint(senderAccount, BN(1000).mul(BN(10).pow(BN(18))));

        await deployer.deploy(UnipoolMock, uniswapToken.address, UltraTokenMock.address);
    }
};
