// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {ethers, upgrades} = require("hardhat");
const {t} = require("tar");

async function main() {
  const provider = ethers.provider;
  const deployer = new ethers.Wallet(process.env.AURORA_PRIVATE_KEY, provider);

  console.log("Deployer account:", deployer.address);

  console.log("Deployer balance:", (await deployer.getBalance()).toString());

  const Validator = await ethers.getContractFactory("Validator");
  const validator = await Validator.deploy(
    "0xe432150cce91c13a887f7D836923d5597adD8E31",
    "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6"
  );

  console.log("Validator address:", validator.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
