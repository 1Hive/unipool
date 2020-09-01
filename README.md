# Ultra Unipool 

#### Ultra Token: https://etherscan.io/token/0xd13c7342e1ef687c5ad21b27c2b65d772cab5c8c

#### Ultra Uniswap Exchange: https://uniswap.info/pair/0x42d52847be255eacee8c3f96b3b223c0b3cc0438

- Number of tokens to send to the rewards contract: ~50k$ `Ultra Token will send exact number`
- Duration of rewards: 30 days
- Start time (time or block): ASAP
- Emission strategy (Halving model or Linear emission): linear emission
- Pool address (needs to be done before the rewards contract is deployed): https://uniswap.info/pair/0x42d52847be255eacee8c3f96b3b223c0b3cc0438

### Run tests

1) Install all dependencies in the root directory execute:
```
$ npm install
```

2) Run tests with:
```
$ npm run test
```

### Deploy to Rinkeby

1) Install all dependencies if not already installed:
```
$ npm install
```

2) Deploy to Rinkeby. Requires adding an infura link and private key that holds ETH to a local file as specified here 
https://hack.aragon.org/docs/cli-intro#set-a-private-key:
```
$ npx truffle deploy --network rinkeby
```
The above command will send both mock UOS and Uniswap tokens to the senders address for testing purposes.

### Deploy to Mainnet

1) Install all dependencies if not already installed:
```
$ npm install
```

2) Update the gas price to whatever is currently being accepted by the network in the `truffle-config.js` file.
By default it is set to 100 Gwei but there's a chance the price will be higher.

3) Deploy to Mainnet. Requires adding an infura link and private key that holds ETH to a local file as specified here 
https://hack.aragon.org/docs/cli-intro#set-a-private-key:
```
$ npx truffle deploy --network mainnet
```

4) Verify on Etherscan. Requires copying an Etherscan API key into `truffle-config.js` at `TruffleConfig.api_keys.etherscan`,
 they are free and require an account here https://etherscan.io/:
```
$ npx truffle run verify Unipool --network mainnet
```

### Create a reward (will be spread across 30 days)

1) Approve the Unipool contract address to take reward amount. If the contract is verified on Etherscan you can
use MetaMask and their contract interface to do this. Otherwise use your preferred method for interacting with contracts.

2) Add a reward amount by going to the Etherscan UI at the Unipool contract address, connecting the MetaMask account 
and excuting `notifyRewardAmount(amount)` with the amount to reward. Remember the amount is padded with 18 zeros. Eg a reward
of 1000 UOS tokens would be 1000000000000000000000. 




