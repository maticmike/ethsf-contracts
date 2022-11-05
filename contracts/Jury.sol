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

    /** STORAGE **/
    bool verdict;

    /** DATA STRUCTURES **/
    //disputes that stret
    mapping(uint256 => Dispute) public disputes;
    mapping(address => bool) public eligibleJuryMembers;
    mapping(uint256 => Jury) public juries;
    mapping(uint256 => bool) public juryIsLive;

    /** MODIFIER **/
    modifier onlyJuryMember() {
        require(
            msg.sender == liveJuryMembers[msg.sender],
            "caller must be jury member"
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

    /*** FUNCTIONS ***/
    function newDispute(
        address _plaintiff,
        address _defendent,
        uint256 _deadline
    ) external {
        Jury liveJury = juries[juryPointer];

        for (uint256 i = 0; i < liveJury.juryMembers.length; i++) {
            require(
                liveJury.juryMembers[i].juryMember != plaintiff ||
                    liveJury.juryMembers[i].juryMember != _defendent,
                "Jury.newDispute: live jury member cannot be involved"
            );
        }

        _newDispute(_plaintiff, _defendent, _deadline);
    }

    function extendDisputeDeadline(uint256 _juryId) external {
        //require (half jurors to agree to extension)
        uint256 newDeadline = disputes[disputeId]
            .deadline += increaseDeadlineAmount;
        emit DisputeDeadlinePostponed(_juryId, newDeadline);
    }

    function voteYes() external onlyJuryMember {}

    function voteNo() external onlyJuryMember {}

    function setJuryType() external {}

    function addEligibleJuryMember(address _newMember) external onlyJuryMember {
        eligibleJuryMembers[_newMember] = true;
        emit NewEligibleJuryMember(_newMember);
    }

    /**
     * @dev lock up jury members to specific jury id
     */
    function newLiveJury() external {
        juryPointer += 1;
        juryIsLive[juryPointer] = true;
        juryIsLive[juryPointer - 1] = false;
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
