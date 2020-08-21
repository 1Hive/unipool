# Ultra Unipool 

#### Ultra Token: https://etherscan.io/token/0xd13c7342e1ef687c5ad21b27c2b65d772cab5c8c

#### Ultra Uniswap Exchange: https://uniswap.info/pair/0x42d52847be255eacee8c3f96b3b223c0b3cc0438

- Number of tokens to send to the rewards contract: ~50k$ `Ultra Token will send exact number`
- Duration of rewards: 30 days
- Start time (time or block): ASAP
- Emission strategy (Halving model or Linear emission): linear emission
- Pool address (needs to be done before the rewards contract is deployed): https://uniswap.info/pair/0x42d52847be255eacee8c3f96b3b223c0b3cc0438

### Run tests

Install all dependencies in the root directory execute:
```
$ npm install
```

Run tests with:
```
$ npm run test
```

### Deploy to Mainnet

Install all dependencies if not already installed:
```
$ npm install
```

Deploy to mainnet (requires adding an infura link and private key that holds ETH to a local file as specified here 
https://hack.aragon.org/docs/cli-intro#set-a-private-key):
```
$ npx truffle deploy --network mainnet
```



