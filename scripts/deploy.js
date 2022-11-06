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
  const provider = ethers.provider;
  const deployer = new ethers.Wallet(process.env.AURORA_PRIVATE_KEY, provider);

  console.log("Deployer account:", deployer.address);

  console.log("Deployer balance:", (await deployer.getBalance()).toString());

  const erc20s = [
    "0x0000000000000000000000000000000000000000",
    "0xcBDF8242ec5e8Da18BAF97cB08B7CfDE346aF4bA",
    "0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
  ];
  const tokenNames = ["Matic", "DAI", "WETH", "APE"];
  const tokenColors = ["#bba3db", "#d8dba3", "#a3dbc5", "#a3d0db"];
  const aggregators = [
    "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
    "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
    "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
    "0x007A22900a3B98143368Bd5906f8E17e9867581b",
  ];

  // const TokenRenderer = await ethers.getContractFactory("TokenRenderer");
  // const tokenrenderer = await upgrades.deployProxy(TokenRenderer, [erc20s, tokenNames, tokenColors, aggregators]);
  // await tokenrenderer.deployed();

  // console.log("TokenRenderer address:", tokenrenderer.address);

  const beneficiary = deployer.address;
  const vestingDate = 1691650712;

  const jurors = [
    "0x6E4D602cC4893e1fa9Fb1BC702E9a2C37522fCc4",
    "0xCb9f7FD7fBED49f94A6e68E419A1160Fe8DFaBbE",
    "0x85C54e29c70b54072C2E6Bbc70e856d56Dd7002A",
    "0x992419d318DE220cD87d036A535665C3405834C0",
    "0xb25910F16bBFd86930d97Dae807b196B4D277e66",
    "0x118E63656C67aD6E0a9BE1a3bFe6e5553182480E",
  ];
  const jurySwap = BN("86400");
  const minJurySize = BN("3");
  const deadline = BN(Math.trunc(Date.now() / 1000 + 86400).toString());

  const SoulFundFactory = await ethers.getContractFactory("SoulFundFactory");
  const soulFundFactory = SoulFundFactory.attach("0xC22ab064A007B2E7c13d8F9559Bce9F09008C6d0");

  let tx = await soulFundFactory.deployNewSoulFund(vestingDate, jurors, jurySwap, minJurySize);
  let txReceipt = await tx.wait();
  let newSoulFundTokenDeployedEvent = txReceipt.events?.filter((events) => events.event == "NewSoulFundTokenDeployed");

  let sfaddress = newSoulFundTokenDeployedEvent[0].args.tokenAddress;

  const SoulFund = await ethers.getContractFactory("SoulFund");
  soulfund = SoulFund.attach(sfaddress);

  console.log("SoulFund address:", soulfund.address);

  let options = {value: ethers.utils.parseEther("0.01")};
  tx = await soulfund.safeMint("0x85C54e29c70b54072C2E6Bbc70e856d56Dd7002A");
  await tx.wait(1);
  tx = await soulfund.depositFund(
    0,
    "0x0000000000000000000000000000000000000000",
    ethers.utils.parseEther("0.01"),
    options
  );
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
