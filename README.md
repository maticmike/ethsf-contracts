# SoulFund Jury - EthSF 2022

SoulFund is a trust fund and RSU distributor which allows the deployment of a soulbound token with a vesting date,

and allows for funds to be deposited. approved NFT contracts can send an NFT from different chains using Axelar bridge

to unlock funds early.

SoulFund Jury is an extension which allows for our jury contract to make decisions on which NFTs to allow early withdrawals,

move a SoulFund token from a lost wallet to a new address, and other changes pertaining to the state of the SoulFund contract.

The SoulFund Jury contract is designed in a way which can be applied to any project that wants to utilize a jury system to make decisions.

| Network | Contract         | Address                                                                                                                              |
| :------ | :--------------- | :----------------------------------------------------------------------------------------------------------------------------------- |
| Goerli  | Axelar Validator | [0xAE534A1b81BFfB64E28e9e0fe7BeD0e57363E0a2](https://goerli.etherscan.io/address/0x6e4d602cc4893e1fa9fb1bc702e9a2c37522fcc4)         |
| Mumbai  | Jury Factory     | [0x0a2eF62347727B72dadfc2686ACF200127E504c5](https://mumbai.polygonscan.com/address/0x0a2eF62347727B72dadfc2686ACF200127E504c5#code) |
| Mumbai  | SoulFund Factory | [0xC22ab064A007B2E7c13d8F9559Bce9F09008C6d0](https://mumbai.polygonscan.com/address/0xC22ab064A007B2E7c13d8F9559Bce9F09008C6d0#code) |

to run unit tests on jury contract run

```shell

npm run test

```
