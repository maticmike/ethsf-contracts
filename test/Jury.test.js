const {expect} = require("chai");
const {ethers} = require("hardhat");

const BN = (number) => ethers.BigNumber.from(number);

let jury;

const jurySwap = BN("86400");
const minJurySize = BN("3");
const deadline = BN(Math.trunc(Date.now() / 1000 + 86400).toString());
let jurors;
let signers;

describe("Jury", function () {
  beforeEach(async function () {
    [admin, jurorOne, jurorTwo, jurorThree, jurorFour, jurorFive, jurorSix] = await ethers.getSigners();
    jurors = [
      jurorOne.address,
      jurorTwo.address,
      jurorThree.address,
      jurorFour.address,
      jurorFive.address,
      jurorSix.address,
    ];

    signers = [jurorOne, jurorTwo, jurorThree, jurorFour, jurorFive, jurorSix];

    jury = await ethers.getContractFactory("Jury");
  });
  describe("constructor", function () {
    it("should revert if minJurySize < 3", async function () {
      await expect(jury.deploy(jurors, jurySwap, 1)).to.be.revertedWith("Jury.constructor: jury size at least 3");
    });
    it("should revert if minJurySize is even", async function () {
      await expect(jury.deploy(jurors, jurySwap, 4)).to.be.revertedWith("Jury.constructor: jury size must be odd");
    });
    it("should revert if not enough jury members", async function () {
      await expect(jury.deploy(jurors, jurySwap, 5)).to.be.revertedWith("Jury.constructor: not enough jury members");
    });
    it("should revert if duplicate members", async function () {
      jurors.push(jurorOne.address);
      jurors.push(jurorTwo.address);
      jurors.push(jurorThree.address);
      jurors.push(jurorFour.address);
      await expect(jury.deploy(jurors, jurySwap, 5)).to.be.revertedWith("Jury.constructor: duplicate Jury member");
    });
    it("should emit NewJuryPoolMember", async function () {
      expect(await jury.deploy(jurors, jurySwap, minJurySize))
        .to.emit(jury, "NewJuryPoolMember")
        .withArgs(jurors[0], 1);
    });
    it("should emit NewLiveJury", async function () {
      expect(await jury.deploy(jurors, jurySwap, minJurySize)).to.emit(jury, "NewLiveJury");
    });
  });
  describe("newDisputeProposal", function () {
    let activeJuryMember;
    beforeEach(async function () {
      this.jury = await jury.deploy(jurors, jurySwap, minJurySize);
      let juryDeployed = await this.jury.deployed();
      let txReceipt = await juryDeployed.deployTransaction.wait();

      let NewLiveJuryEvent = txReceipt.events?.filter((events) => events.event == "NewLiveJury");
      activeJuryMember = signers[parseInt(NewLiveJuryEvent[0].args.juryMembers[0]) - 1];
    });
    it("should revert if called by an active jury member", async function () {
      await expect(this.jury.connect(activeJuryMember).newDisputeProposal(jurySwap)).to.be.revertedWith(
        "Jury.newDisputeProposal: juror already in jury"
      );
    });
    it("should revert if deadline in past", async function () {
      await expect(this.jury.connect(admin).newDisputeProposal(jurySwap)).to.be.revertedWith(
        "Jury.newDisputeProposal: deadline has already past"
      );
    });
    it("should emit NewDisputeProposal", async function () {
      await expect(this.jury.connect(admin).newDisputeProposal(deadline))
        .to.emit(this.jury, "NewDisputeProposal")
        .withArgs(admin.address, 1, 0, deadline);
    });
  });
  describe("approveDisputeProposal", function () {
    beforeEach(async function () {});
  });
  describe("extendDisputeDeadline", function () {
    beforeEach(async function () {});
  });
  describe("vote", function () {
    beforeEach(async function () {});
  });
  describe("trigger vote finalized", function () {
    beforeEach(async function () {});
  });
});
