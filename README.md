# Orica Royalty NFT and Trader-Contract

## About
* Mint NFT Contract with Royalty optional of charities and artist.
* NFT Trader with Royalty that was configured by artist when minting

## Installation
```console
$ yarn install
```

## Usage

### Build
```console
$ yarn compile
```

### Test
```console
$ yarn test
```


### Deploying contracts to BSC Testnet (Public)

#### ETH Testnet - Bsc Testnet
* Environment variables
    - Create a `.env` file with its values:
```
INFURA_API_KEY=[YOUR_INFURA_API_KEY_HERE]
DEPLOYER_PRIVATE_KEY=[YOUR_DEPLOYER_PRIVATE_KEY_without_0x]
REPORT_GAS=<true_or_false>
```

* Deploy the contract
```console
$ yarn hardhat bsctestnet:NFTRoyalty --name <NFT_TOKEN_NAME> --symbol <NFT_SYMBOL_NAME>
```