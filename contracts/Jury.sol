// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IJury.sol";
import "hardhat/console.sol";

/**
 * @dev One jury per protocol
 */
contract Jury is IJury, Pausable {
    uint256 constant increaseDeadlineAmount = 86400;
    uint256 s_jurySwap;
    uint256 s_minJurySize;
    uint256 s_jurorLength;

    uint256 s_juryId;
    uint256 disputeId;
    uint256 disputeProposalId;

    /** DATA STRUCTURES **/
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => DisputeProposal) public disputeProposals;

    mapping(uint256 => JuryMember) juryPool;

    // indicies
    mapping(address => uint256) public juryPoolMembers;

    // juryId to juryIndicies
    mapping(uint256 => uint256[]) public juries;
    // juryId to expiration
    mapping(uint256 => uint256) public juryExpiration;

    mapping(uint256 => mapping(uint256 => Vote)) juryMemberVote;

    /** MODIFIER **/
    modifier onlyJuryPoolMember() {
        require(juryPoolMembers[msg.sender] > 0, "caller must be jury pool member");
        _;
    }

    function _isInJury(uint256 _juryId) internal view returns (bool) {
        JuryMember memory juror = juryPool[juryPoolMembers[msg.sender]];
        if (juror.lastJuryId == _juryId) {
            return true;
        }
        return false;
    }

    /*** CONSTRUCTOR ***/
    constructor(
        address[] memory _initialJuryMembers,
        uint96 _jurySwap,
        uint8 _minJurySize
    ) {
        require(_minJurySize > 1, "Jury.constructor: jury size at least 3");
        require(_minJurySize % 2 > 0, "Jury.constructor: jury size must be odd");
        require(_initialJuryMembers.length >= _minJurySize * 2, "Jury.constructor: not enough jury members");
        for (uint256 i = 0; i < _initialJuryMembers.length; i++) {
            require(juryPoolMembers[_initialJuryMembers[i]] == 0, "Jury.constructor: duplicate Jury member");
            juryPoolMembers[_initialJuryMembers[i]] = i + 1;
            juryPool[i + 1].valid = true;
            emit NewJuryPoolMember(_initialJuryMembers[i], i + 1);
        }
        s_juryId = 1;
        s_jurorLength = _initialJuryMembers.length;
        s_minJurySize = _minJurySize;
        s_jurySwap = _jurySwap;

        _randomizeJuryMembers(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, uint256(1)))));
    }

    /*** FUNCTIONS ***/
    function newDisputeProposal(uint256 _deadline) external {
        _checkJury();
        uint256 jid = s_juryId;
        require(!_isInJury(jid), "Jury.newDisputeProposal: juror already in jury");
        require(_deadline > block.timestamp, "Jury.newDisputeProposal: deadline has already past");
        uint256 id = disputeProposalId;
        disputeProposalId++;
        disputeProposals[id] = DisputeProposal({
            proposer: msg.sender,
            juryId: jid,
            isApproved: false,
            deadline: _deadline
        });

        emit NewDisputeProposal(msg.sender, jid, id, _deadline);
    }

    function approveDisputeProposal(uint256 _disputeProposalId) external onlyJuryPoolMember {
        _checkJury();
        DisputeProposal memory disputeProposal = disputeProposals[_disputeProposalId];
        // approver is not proposer
        require(!disputeProposal.isApproved, "Jury.approveDisputeProposal: already approved");
        require(
            msg.sender != disputeProposal.proposer,
            "Jury.approvedDisputeProposal: proposer can not approve dispute"
        );
        // change this to conditional
        require(block.timestamp < disputeProposal.deadline, "Jury.approveDisputeProposal: deadline has past");

        //set new current approved jurors
        disputeProposals[_disputeProposalId].isApproved = true;
        juryPool[juryPoolMembers[msg.sender]].disputesApproved++;
        _newDispute(disputeProposal.deadline);
    }

    function extendDisputeDeadline(uint256 _disputeId) external {
        _checkJury();
        //require (half jurors to agree to extension)
        require(_isInJury(disputes[_disputeId].juryId), "Jury.extendDisputeDeadline: not in jury");
        uint256 newDeadline = disputes[_disputeId].deadline += increaseDeadlineAmount;
        emit DisputeDeadlinePostponed(_disputeId, newDeadline);
    }

    function vote(uint256 _disputeId, bool _vote) external {
        Dispute memory dispute = disputes[_disputeId];
        // require not resolved
        require(!dispute.resolved, "Jury.vote: dispute already resolved");
        // require sender is in jury assigned to dispute id
        require(_isInJury(dispute.juryId), "Jury.vote: member not in jury");

        uint256 juror = juryPoolMembers[msg.sender];
        if (block.timestamp >= dispute.deadline) {
            _finalizeVerdict(_disputeId, dispute.juryId);
        } else {
            juryMemberVote[_disputeId][juror] = Vote({decision: _vote, voted: true});

            emit Voted(juror, _disputeId, _vote);
        }
    }

    // removing for now, adding to jury would make the jury even. Would need to wait until 2 pending or 1 removed

    function addJuryPoolMember(address _newMember) external onlyJuryPoolMember {
        require(juryPoolMembers[_newMember] == 0, "Jury.addJuryPoolMember: Juror already exists");
        s_jurorLength++;
        uint256 index = s_jurorLength;
        juryPoolMembers[_newMember] = index;
        juryPool[index].valid = true;

        emit NewJuryPoolMember(_newMember, index);
    }

    // should be modified in production to restrict to deadline having passed
    function forceClose(uint256 _disputeId) external {
        // require timestamp has passed in production

        _finalizeVerdict(_disputeId, disputes[_disputeId].juryId);
    }

    /*** HELPER FUNCTIONS ***/
    function _newDispute(uint256 _deadline) internal {
        uint256 id = disputeId;
        uint256 jid = s_juryId;
        disputeId++;
        disputes[id] = Dispute({juryId: jid, deadline: _deadline, verdict: false, resolved: false});
        emit NewDispute(id, jid, _deadline);
    }

    function _finalizeVerdict(uint256 _disputeId, uint256 _juryId) internal {
        uint256[] memory jury = juries[_juryId];
        uint8 votesFor;

        for (uint8 i = 0; i < jury.length; i++) {
            Vote memory votes = juryMemberVote[_disputeId][jury[i]];
            if (votes.voted) {
                if (votes.decision) {
                    votesFor++;
                }
                juryPool[jury[i]].disputesResolved++;
            }
        }

        if (s_minJurySize / 2 < votesFor) {
            disputes[_disputeId].verdict = true;
        }

        disputes[_disputeId].resolved = true;

        emit DisputeResolved(_disputeId, disputes[_disputeId].verdict);
    }

    function _checkJury() internal {
        uint256 id = s_juryId;
        if (block.timestamp >= juryExpiration[id]) {
            emit JuryDutyCompleted(id);
            s_juryId++;
            _randomizeJuryMembers(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, id + 1))));
        }
    }

    // seed is being set by psuedo randomness however VRF should be integrated
    function _randomizeJuryMembers(uint256 _seed) internal {
        uint256 nonce = 0;
        uint256 length = s_jurorLength;
        uint256 id = s_juryId;

        for (uint256 i = 0; i < s_minJurySize; ) {
            uint256 juror = (uint256(keccak256(abi.encodePacked(_seed, nonce))) % length) + 1;
            JuryMember memory selected = juryPool[juror];
            // can't be selected twice in a row
            if (selected.valid && (selected.lastJuryId == 0 || selected.lastJuryId + 1 < id)) {
                juryPool[juror].lastJuryId = id;
                juries[id].push(juror);
                i++;
            }

            nonce++;
        }

        uint256 expires = block.timestamp + s_jurySwap;
        juryExpiration[id] = expires;
        emit NewLiveJury(id, juries[id], expires);
    }
}

// add metadata about the dispute to ipfs
