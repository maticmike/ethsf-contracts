// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IJury {
    struct Jury {
        address juryId;
        JuryMember[] juryMembers;
    }

    struct JuryMember {
        address memberAddr;
        uint256 jurysParticipated;
        uint256 disputesResolved;
        bool vote;
    }

    struct Dispute {
        uint256 juryId;
        uint256 disputeId;
        uint256 deadline;
        address plaintiff;
        address defendent;
        bool verdict;
    }

    //Jury Events
    event NewLiveJury(uint256 juryId, address[] indexed juryMemebers);
    event NewEligibleJuryMember(address juryMemeber);
    event RemovedJuryMember(address juryMember);
    event JuryDutyCompleted(uint256 indexed jurydId);

    //Dispute Events
    event NewDispute(uint256 juryId, uint256 disputeId);
    event DisputeDeadlinePostponed(uint256 juryId, uint256 newDeadline);
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
