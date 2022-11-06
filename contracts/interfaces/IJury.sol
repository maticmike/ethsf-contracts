// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IJury {
    struct Votes {
        bool decision;
        bool voted;
    }

    struct JuryMember {
        address memberAddr;
        uint256 jurysParticipated;
        uint256 disputesApproved;
        uint256 disputesResolved;
    }

    struct DisputeProposal {
        address[] approvedJurors;
        bool isApproved;
        uint256 deadline;
        address plaintiff;
        address defendent;
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
    event NewJuryPoolMember(address juryMemeber);
    event RemovedJuryMember(address juryMember);
    event JuryDutyCompleted(uint256 indexed jurydId);
    event VotedYes(address indexed juryMember, uint256 disputeId);
    event VotedNo(address indexed juryMember, uint256 disputeId);

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

    // function addJuryPoolMember() external;

    // function removeJuryPoolMember() external;

    /**
     * @dev lock up jury members to specific jury id
    //  */
    // function newLiveJury() external;

    // /** MICRO (ongoing dispute) **/
    // function newDispute() external;

    // function voteYes() external;

    // function voteNo() external;
}
