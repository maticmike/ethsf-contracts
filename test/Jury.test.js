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
    let activeJuryMember;
    beforeEach(async function () {
      this.jury = await jury.deploy(jurors, jurySwap, minJurySize);
      let juryDeployed = await this.jury.deployed();
      let txReceipt = await juryDeployed.deployTransaction.wait();

      let NewLiveJuryEvent = txReceipt.events?.filter((events) => events.event == "NewLiveJury");
      activeJuryMember = signers[parseInt(NewLiveJuryEvent[0].args.juryMembers[0]) - 1];

      await this.jury.connect(admin).newDisputeProposal(deadline);
    });
    it("should revert if already approved", async function () {
      await this.jury.connect(activeJuryMember).approveDisputeProposal(0);
      await expect(this.jury.connect(activeJuryMember).approveDisputeProposal(0)).to.be.revertedWith(
        "Jury.approveDisputeProposal: already approved"
      );
    });
    it("should revert if proposer approves", async function () {
      await this.jury.connect(activeJuryMember).addJuryPoolMember(admin.address);
      await expect(this.jury.connect(admin).approveDisputeProposal(0)).to.be.revertedWith(
        "Jury.approvedDisputeProposal: proposer can not approve dispute"
      );
    });
    it("should emit NewDispute", async function () {
      await expect(this.jury.connect(activeJuryMember).approveDisputeProposal(0))
        .to.emit(this.jury, "NewDispute")
        .withArgs(0, 1, deadline);
    });
  });
  //   describe("extendDisputeDeadline", function () {
  //     beforeEach(async function () {});
  //   });
  describe("vote", function () {
    let activeJuryMember;
    let jurorId;
    beforeEach(async function () {
      this.jury = await jury.deploy(jurors, jurySwap, minJurySize);
      let juryDeployed = await this.jury.deployed();
      let txReceipt = await juryDeployed.deployTransaction.wait();

      let NewLiveJuryEvent = txReceipt.events?.filter((events) => events.event == "NewLiveJury");
      jurorId = parseInt(NewLiveJuryEvent[0].args.juryMembers[0]);
      activeJuryMember = signers[jurorId - 1];
      await this.jury.connect(admin).newDisputeProposal(deadline);
      await this.jury.connect(activeJuryMember).approveDisputeProposal(0);
    });
    it("should revert if already resolved", async function () {
      await this.jury.forceClose(0);
      await expect(this.jury.connect(activeJuryMember).vote(0, true)).to.be.revertedWith(
        "Jury.vote: dispute already resolved"
      );
    });
    it("should revert if not in jury", async function () {
      await expect(this.jury.connect(admin).vote(0, true)).to.be.revertedWith("Jury.vote: member not in jury");
    });
    it("should emit Voted event", async function () {
      await expect(this.jury.connect(activeJuryMember).vote(0, true))
        .to.emit(this.jury, "Voted")
        .withArgs(jurorId, 0, true);
    });
  });
  describe("trigger vote finalized", function () {
    beforeEach(async function () {
      this.jury = await jury.deploy(jurors, jurySwap, minJurySize);
      let juryDeployed = await this.jury.deployed();
      let txReceipt = await juryDeployed.deployTransaction.wait();

      let NewLiveJuryEvent = txReceipt.events?.filter((events) => events.event == "NewLiveJury");
      jurorIds = [
        parseInt(NewLiveJuryEvent[0].args.juryMembers[0]),
        parseInt(NewLiveJuryEvent[0].args.juryMembers[1]),
        parseInt(NewLiveJuryEvent[0].args.juryMembers[2]),
      ];
      activeJuryMember = [signers[jurorIds[0] - 1], signers[jurorIds[1] - 1], signers[jurorIds[2] - 1]];
      await this.jury.connect(admin).newDisputeProposal(deadline);
      await this.jury.connect(activeJuryMember[0]).approveDisputeProposal(0);
    });
    it("should emitDisputeResolved with false verdict", async function () {
      await expect(this.jury.forceClose(0)).to.emit(this.jury, "DisputeResolved").withArgs(0, false);
    });
    it("should emitDisputeResolved with true verdict", async function () {
      await this.jury.connect(activeJuryMember[0]).vote(0, true);
      await this.jury.connect(activeJuryMember[1]).vote(0, true);
      await this.jury.connect(activeJuryMember[2]).vote(0, false);
      await expect(this.jury.forceClose(0)).to.emit(this.jury, "DisputeResolved").withArgs(0, true);
    });
  });
});
