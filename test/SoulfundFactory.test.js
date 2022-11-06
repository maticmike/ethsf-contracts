const {expect} = require("chai");
const {ethers} = require("hardhat");

const BN = (number) => ethers.BigNumber.from(number);

let soulFundFactory;
let soulFund;
let tokenRenderer;

const futureVest = BN("1699142400");
const pastDate = BN("1636070400");
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

// Axelar gateway / gas receiver mumbai
const gateway = "0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B";
const gasReceiver = "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6";

describe("SoulFundFactory", function () {
  beforeEach(async function () {
    [admin, granter, beneficiary] = await ethers.getSigners();

    tokenRenderer = await ethers.getContractFactory("TokenRenderer");
    soulFund = await ethers.getContractFactory("SoulFund");
    soulFundFactory = await ethers.getContractFactory("SoulFundFactory");

    this.renderer = await upgrades.deployProxy(tokenRenderer, [erc20s, tokenNames, tokenColors, aggregators]);
    await this.renderer.deployed();

    this.factory = await soulFundFactory.deploy(this.renderer.address, gateway, gasReceiver);
  });
  describe("deployNewSoulFund", function () {
    it("should revert if vesting date in past", async function () {
      await expect(this.factory.deployNewSoulFund(pastDate)).to.be.revertedWith(
        "SoulFundFactory.deployNewSoulFund: vesting must be sometime in the future"
      );
    });
    it("should emit NewSoulFundTokenDeployed event", async function () {
      let tx = await this.factory.deployNewSoulFund(futureVest);
      let txReceipt = await tx.wait();
      let newSoulFundTokenDeployedEvent = txReceipt.events?.filter(
        (events) => events.event == "NewSoulFundTokenDeployed"
      );

      expect(newSoulFundTokenDeployedEvent[0].args.granter).to.equal(admin.address);
      expect(newSoulFundTokenDeployedEvent[0].args.vestingDate).to.equal(futureVest);
    });
    it("should should allow minting of new SoulFund token", async function () {
      let tx = await this.factory.deployNewSoulFund(futureVest);
      let txReceipt = await tx.wait();
      let newSoulFundTokenDeployedEvent = txReceipt.events?.filter(
        (events) => events.event == "NewSoulFundTokenDeployed"
      );

      let localSoulFund = soulFund.attach(newSoulFundTokenDeployedEvent[0].args.tokenAddress);

      await expect(localSoulFund.connect(granter).safeMint(beneficiary.address)).to.be.reverted;
      await expect(localSoulFund.connect(admin).safeMint(beneficiary.address))
        .to.emit(localSoulFund, "Transfer")
        .withArgs(ethers.constants.AddressZero, beneficiary.address, 0);
    });
    it("should should allow funding of new SoulFund token", async function () {
      let tx = await this.factory.deployNewSoulFund(futureVest);
      let txReceipt = await tx.wait();
      let newSoulFundTokenDeployedEvent = txReceipt.events?.filter(
        (events) => events.event == "NewSoulFundTokenDeployed"
      );

      let localSoulFund = soulFund.attach(newSoulFundTokenDeployedEvent[0].args.tokenAddress);

      await localSoulFund.safeMint(beneficiary.address);

      let options = {value: ethers.utils.parseEther("1")};
      await expect(localSoulFund.depositFund(0, ethers.constants.AddressZero, ethers.utils.parseEther("1"), options))
        .to.emit(localSoulFund, "FundDeposited")
        .withArgs(0, ethers.constants.AddressZero, ethers.utils.parseEther("1"), beneficiary.address);
    });
  });
});
