// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IJury {
    struct JuryMember {
        address project;
        address juryMember;
        uint256 jurysParticipated;
        uint256 disputesResolved;
        bool vote;
    }

    struct Dispute {
        uint256 juryId;
        uint256 disputeId;
        address plaintiff;
        address defendent;
        bool verdict;
    }

    event NewLiveJury(uint256 juryId, address[] indexed juryMemebers);

    event NewEligibleJuryMember(address juryMemeber);
    event RemovedJuryMember(address juryMember);
    event JuryDutyCompleted(uint256 indexed jurydId);

    event NewDispute(uint256 juryId, uint256 disputeId);
    event DisputeResolved(bool verdict, uint256 juryId);
    event JuryMemberVoted(bool vote, address indexed juryMember);

    /** MACRO (jury configuraiton) **/

    /**
     * @dev majority rules or unanimous decision
     */
    function setJuryType() external;

    function addEligibleJuryMember() external;

    function removeEligibleJuryMember() external;

    /**
     * @dev lock up jury members to specific jury id
     */
    function newLiveJury() external;

    /** MICRO (ongoing dispute) **/
    function newDispute() external;

    function voteYes() external;

    function voteNo() external;
}
