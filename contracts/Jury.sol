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

    mapping(uint256 => mapping(address => Votes)) juryMemberVote;

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

    /*** FUNCTIONS ***/
    function newDisputeProposal(
        address _plaintiff,
        address _defendent,
        uint256 _deadline
    ) external {
        JuryMember[] memory liveJuryMembers = juries[juryPointer];

        for (uint256 i = 0; i < liveJuryMembers.length; i++) {
            require(
                liveJuryMembers[i].memberAddr != _plaintiff ||
                    liveJuryMembers[i].memberAddr != _defendent,
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

        for (uint256 i = 0; i < currentApprovedJurors.length; i++) {
            require(
                currentApprovedJurors[i] != msg.sender,
                "Jury.approveDisputeProposal: jurror already approved"
            );
        }

        //set new current approved jurors
        disputeProposals[_disputeProposalId].approvedJurors.push(msg.sender);
        DisputeProposal memory disputeProposal = disputeProposals[
            _disputeProposalId
        ];
        if (disputeProposals[_disputeProposalId].approvedJurors.length > 1) {
            _newDispute(
                disputeProposal.plaintiff,
                disputeProposal.defendent,
                disputeProposal.deadline
            );
        }
    }

    function extendDisputeDeadline(uint256 _disputeId) external {
        //require (half jurors to agree to extension)
        uint256 newDeadline = disputes[_disputeId]
            .deadline += increaseDeadlineAmount;
        emit DisputeDeadlinePostponed(_disputeId, newDeadline);
    }

    function voteYes(uint256 _disputeId) external onlyJuryMember {
        Dispute dispute = disputes[_disputeId];

        //require(dispute.juryMembers[]);
        dispute.juryMemberVote[msg.sender] = true;
        dispute.juryMemberVoteCounter[msg.sender] += 1;
        emit VotedYes(msg.sender, _disputeId);
    }

    function voteNo() external onlyJuryMember {
        Dispute dispute = disputes[_disputeId];
        require(dispute.juryMembers[]);
        dispute.juryMemberVote[msg.sender] = false;
        dispute.juryMemberVoteCounter[msg.sender] += 1;
        emit VotedNo(msg.sender, _disputeId);
    }

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
        JuryMember[] memory juryMembers = juries[juryPointer];
        for (uint256 i = 0; i < _juryMembers.length; i++) {
            juryMembers[i].memberAddr = _juryMembers[i];
        }
        emit JuryDutyCompleted(juryPointer);
    }

    /*** HELPER FUNCTIONS ***/
    function _newDispute(
        address _plaintiff,
        address _defendent,
        uint256 _deadline
    ) internal {
        JuryMember[] memory liveJuryMembers = juries[juryPointer];

        disputeId += 1;
        disputes[disputeId] = Dispute({
            juryId: juryPointer,
            disputeId: disputeId,
            deadline: _deadline,
            plaintiff: _plaintiff,
            defendent: _defendent,
            verdict: false,
            juryMembers: liveJuryMembers
        });
        emit NewDispute(disputeId, juryPointer);
    }

    function _setVerdict() internal {}

    function _randomizeJuryMembers() internal {}
}

// add metadata about the dispute to ipfs
