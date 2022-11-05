# SoulFund Jury - EthSF 2022

SoulFund is a trust fund and RSU distributor which allows the deployment of a soulbound token with a vesting date,
and allows for funds to be deposited. approved NFT contracts can send an NFT from different chains using Axelar bridge
to unlock funds early.

SoulFund Jury is an extension which allows for our jury contract to make decisions on which NFTs to allow early withdrawals,
move a SoulFund token from a lost wallet to a new address, and other changes pertaining to the state of the SoulFund contract.

The SoulFund Jury contract is designed in a way which can be applied to any project that wants to utilize a jury system to make decisions.

To deploy to Near (Aurora testnet)

```shell
npm run deploy_testnet
```
