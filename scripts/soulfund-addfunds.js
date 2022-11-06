//0xe316a9808B717042ec7cE5C7ECDEC3B49F8F2524
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {ethers, upgrades} = require("hardhat");
const {t} = require("tar");

const BN = (number) => ethers.BigNumber.from(number);

async function main() {
  const SoulFund = await ethers.getContractFactory("SoulFund");
  soulfund = SoulFund.attach("0xe316a9808B717042ec7cE5C7ECDEC3B49F8F2524");

  console.log("SoulFund address:", soulfund.address);

  let options = {value: ethers.utils.parseEther("0")};
  tx = await soulfund.depositFund(0, "0xcBDF8242ec5e8Da18BAF97cB08B7CfDE346aF4bA", ethers.utils.parseEther("20"));
  await tx.wait(1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
