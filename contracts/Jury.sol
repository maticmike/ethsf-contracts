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
        JuryMember[] memory liveJuryMembers = juries[juryPointer];
        for (uint256 i = 0; i < liveJuryMembers.length; i++) {
            require(
                msg.sender == liveJuryMembers[i].memberAddr,
                "caller must be jury member"
            );
        }
        _;
    }

    modifier onlyJuryPoolMember() {
        require(juryPoolMembers[msg.sender], "caller must be jury pool member");
        _;
    }

    /*** CONSTRUCTOR ***/
    constructor(address[] memory _initialJuryMembers) {
        require(
            _initialJuryMembers.length == minJurySize,
            "Jury.constructor: not enough jury members"
        );
        for (uint256 i = 0; i < _initialJuryMembers.length; i++) {
            juryPoolMembers[_initialJuryMembers[i]] = true;
            emit NewJuryPoolMember(_initialJuryMembers[i]);
        }
        juryPointer += 1;
        juryIsLive[juryPointer] = true;
    }

    // /*** FUNCTIONS ***/
    function newDisputeProposal(
        address _plaintiff,
        address _defendent,
        uint256 _deadline
    ) external {
        JuryMember[] memory juryMembers = juries[juryPointer];

        for (uint256 i = 0; i < juryMembers.length; i++) {
            require(
                juryMembers[i].memberAddr != _plaintiff ||
                    juryMembers[i].memberAddr != _defendent,
                "Jury.newDispute: live jury member cannot be involved"
            );
        }

        disputeProposals[disputeProposalId] = DisputeProposal({
            approvedJurors: new address[](0),
            isApproved: false,
            deadline: _deadline,
            plaintiff: _plaintiff,
            defendent: _defendent
        });
    }

    function approveDisputeProposal(uint256 _disputeProposalId)
        external
        onlyJuryPoolMember
    {
        address[] memory currentApprovedJurors = disputeProposals[
            _disputeProposalId
        ].approvedJurors;
        disputeProposals[_disputeProposalId]
            .approvedJurors = currentApprovedJurors;
        // if(disputeProposals[_disputeProposalId].approvedJurors > 1)
    }

    function newDisputeSubmission(uint256 _disputeProposalId)
        external
        onlyJuryPoolMember
    {
        require(
            disputeProposals[_disputeProposalId].approvedJurors.length >= 2,
            "Jury.newDisputeSubmission: not enough approvals for dispute"
        );
        address plaintiff = disputeProposals[_disputeProposalId].plaintiff;
        address defendent = disputeProposals[_disputeProposalId].defendent;
        uint256 deadline = disputeProposals[_disputeProposalId].deadline;
        _newDispute(plaintiff, defendent, deadline);
    }

    function extendDisputeDeadline(uint256 _disputeId) external {
        //require (half jurors to agree to extension)
        uint256 newDeadline = disputes[_disputeId]
            .deadline += increaseDeadlineAmount;
        emit DisputeDeadlinePostponed(_disputeId, newDeadline);
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
    function newLiveJury(address[] memory _juryMembers) external {
        // require juryMember be from pooled members
        juryPointer += 1;
        juryIsLive[juryPointer] = true;
        juryIsLive[juryPointer - 1] = false;
        for (uint256 i = 0; i < _juryMembers.length; i++) {
            // JuryMember juryMember = juries[i];
            // juries[juryPointer].memberAddr = _juryMembers[i];
            // juries[juryPonter].jurysParticipated = juryMember.jurysParticipated;
            // juries[juryPointer].disputesApproved = juryMember.disputesApproved;
            // juries[juryPointer].disputedResolved = juryMember.disputedResolved;
            // juries[juryPointer].vote = false;
        }
        emit JuryDutyCompleted(juryPointer);
    }

    /*** HELPER FUNCTIONS ***/
    function _newDispute(
        address _plaintiff,
        address _defendent,
        uint256 _deadline
    ) internal {
        disputeId += 1;
        disputes[disputeId] = Dispute({
            juryId: juryPointer,
            disputeId: disputeId,
            deadline: _deadline,
            plaintiff: _plaintiff,
            defendent: _defendent,
            verdict: false
        });
        emit NewDispute(disputeId, juryPointer);
    }

    function _setVerdict() internal {}

    function _randomizeJuryMembers() internal {}
}

// add metadata about the dispute to ipfs
