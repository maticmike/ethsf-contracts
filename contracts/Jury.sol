// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IJury.sol";

/**
 * @dev One jury per protocol
 */
contract Jury is IJury, Pausable {
    uint256 constant minJurySize = 10;
    uint256 constant increaseDeadlineAmount = 86400;

    uint256 juryPointer;
    uint256 disputeId;
    uint256 disputeProposalId;

    /** STORAGE **/
    bool verdict;

    /** DATA STRUCTURES **/
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => DisputeProposal) public disputeProposals;

    mapping(address => bool) public juryPoolMembers;
    mapping(uint256 => JuryMember[]) public juries;
    mapping(uint256 => bool) public juryIsLive;

    /** MODIFIER **/
    modifier onlyJuryMember() {
        require(
            msg.sender == liveJuryMembers[msg.sender],
            "caller must be jury member"
        );
        _;
    }

    modifier onlyJuryPoolMember() {
        require(
            msg.sender == juryPoolMembers[msg.sender],
            "caller must be jury pool member"
        );
        _;
    }

    /*** CONSTRUCTOR ***/
    constructor(address[] _initialJuryMembers) {
        require(
            _initialJuryMembers.length == minJurySize,
            "Jury.constructor: not enough jury members"
        );
        for (uint256 i = 0; i < _initialJuryMembers.length; i++) {
            eligibleJuryMembers[_initialJuryMembers[i]] = true;
            emit NewEligibleJuryMember(_initialJuryMembers[i]);
        }
        juryPointer += 1;
        juryIsLive[juryPointer] = true;
    }

    // /*** FUNCTIONS ***/
    // function newDisputeProposal(
    //     address _plaintiff,
    //     address _defendent,
    //     uint256 _deadline
    // ) external {
    //     Jury liveJury = juries[juryPointer];

    //     for (uint256 i = 0; i < liveJury.juryMembers.length; i++) {
    //         require(
    //             liveJury.juryMembers[i].juryMember != plaintiff ||
    //                 liveJury.juryMembers[i].juryMember != _defendent,
    //             "Jury.newDispute: live jury member cannot be involved"
    //         );
    //     }

    //     disputeProposals[disputeProposalId] = DisputeProposal({approvedJurors: [], isApproved: false});
    // }

    function approveDisputeProposal(uint256 _disputeProposalId) onlyJurorPoolMember  external {
        address[] currentApprovedJurors = disputeProposals[_disputeProposalId].approvedJurors
        currentApprovedJurors.push(msg.sender);
        disputeProposals[_disputeProposalId].approvedJurors = currentApprovedJurors;
        if(disputeProposals[_disputeProposalId].approvedJurors > 1)
    }

    function newDisputeSubmission(uint256 _disputeProposalId) onlyJuryPoolMember external {
        require(disputeProposals[_disputeProposalId].approvedJurors.length >= 2, "Jury.newDisputeSubmission: not enough approvals for dispute");
        _newDispute(_plaintiff, _defendent, _deadline);
    }

    function extendDisputeDeadline(uint256 _disputeId) external {
        //require (half jurors to agree to extension)
        uint256 newDeadline = disputes[_disputeId].deadline += increaseDeadlineAmount;
        emit DisputeDeadlinePostponed(_juryId, newDeadline);
    }

    function voteYes() external onlyJuryMember {}

    function voteNo() external onlyJuryMember {}

    function setJuryType() external {}

    function addJuryPoolMember(address _newMember) external onlyJuryMember {
        juryPoolMembers[_newMember] = true;
        emit NewJuryPoolMember(_newMember);
    }

    /**
     * @dev lock up jury members to specific jury id
     */
    function newLiveJury(address[] _juryMembers) external {
        // require juryMember be from pooled members
        juryPointer += 1;
        juryIsLive[juryPointer] = true;
        juryIsLive[juryPointer - 1] = false;
            juries[juryPointer].jurydId = juryPointer;
        for (uint256 i = 0; i < _juryMembers.length; i++) {
                    // JuryMember juryMember = juries[i];
            // juries[juryPointer].memberAddr = _juryMembers[i];
            // juries[juryPonter].jurysParticipated = juryMember.jurysParticipated;
            // juries[juryPointer].disputesApproved = juryMember.disputesApproved;
            // juries[juryPointer].disputedResolved = juryMember.disputedResolved;
            // juries[juryPointer].vote = false;   
        };
        emit JuryDutyCompleted(juryPointer);
    }

    /*** HELPER FUNCTIONS ***/
    function _newDispute(
        address _plaintiff,
        address _defendent,
        uint256 _deadline
    ) internal {
        disputeId += 1;
        disputessfd[disputeId] = Dispute({
            juryPointer: juryPointer,
            disputeId: disputeId,
            deadline: _deadline,
            plaintiff: _plaintiff,
            defendent: _denfendent,
            verdict: false
        });
        emit NewDispute(disputeID, juryPointer);
    }

    function _setVerdict() internal {}

    function _randomizeJuryMembers() internal {}
}

// add metadata about the dispute to ipfs
