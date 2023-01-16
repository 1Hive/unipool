const UnipoolFactory = artifacts.require("./UnipoolFactory.sol");
// const Unipool = artifacts.require("./Unipool.sol");
// const HoneyTokenMock = artifacts.require('./HoneyTokenMock.sol');
// const Token = artifacts.require("./Token.sol");

// const argValue = (arg, defaultValue) =>
//   process.argv.includes(arg)
//     ? process.argv[process.argv.indexOf(arg) + 1]
//     : defaultValue;
// const network = () => argValue("--network", "local");

module.exports = async function (deployer, network) {
  console.log("network", network);
  //   if (network === "goerli") {
  await deployer.deploy(UnipoolFactory);
  const unipool = await UnipoolFactory.deployed();
  console.log("UnipoolFactory", unipool.address.toLowerCase());
  //   }
  // if (network() === 'xdai') {
  //     await deployer.deploy(UnipoolFactory);
  // } else {
  //     const senderAccount = (await web3.eth.getAccounts())[0];
  //     const BN = web3.utils.toBN;
  //
  //     await deployer.deploy(HoneyTokenMock, senderAccount);
  //
  //     await deployer.deploy(Token);
  //     const uniswapToken = await Token.at(Token.address);
  //     await uniswapToken.mint(senderAccount, BN(1000).mul(BN(10).pow(BN(18))));
  //
  //     await deployer.deploy(Unipool, uniswapToken.address, HoneyTokenMock.address);
  // }
};
