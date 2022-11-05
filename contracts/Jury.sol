// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IJury.sol";

/**
 * @dev One jury per protocol
 */
contract Jury is IJury, Pausable {
    uint256 juryId;
    uint256 disputeId;

    /** STORAGE **/
    bool verdict;

    /** DATA STRUCTURES **/
    mapping(uint256 => Dispute) public disputes;
    mapping(address => bool) public eligibleJuryMembers;
    mapping(address => JuryMember) public liveJuryMembers;

    /** MODIFIER **/
    modifier onlyJuryMember() {
        require(
            msg.sender == liveJuryMembers[msg.sender],
            "caller must be jury member"
        );
        _;
    }

    constructor(address[] _initialJuryMembers) {
        for (uint256 i = 0; i < _initialJuryMembers.length; i++) {
            eligibleJuryMembers[_initialJuryMembers[i]] = true;
            emit NewEligibleJuryMember(_initialJuryMembers[i]);
        }
    }

    /*** FUNCTIONS ***/
    function newDispute(address _plaintiff, address _defendent) external {
        _newDispute(_plaintiff, _defendent);
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
        juryId += 1;
        emit JuryDutyCompleted(juryId);
    }

    /*** HELPER FUNCTIONS ***/
    function _newDispute(address _plaintiff, address _defendent) internal {
        disputeId += 1;
        disputessfd[disputeId] = Dispute({
            juryId: juryId,
            disputeId: disputeId,
            plaintiff: _plaintiff,
            defendent: _denfendent,
            verdict: false
        });
        emit NewDispute(disputeID, juryId);
    }

    function _setVerdict() internal {}

    function _randomizeJuryMembers() internal {}
}

// add metadata about the dispute to ipfs
