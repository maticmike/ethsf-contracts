// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IJury {
    struct Vote {
        bool decision;
        bool voted;
    }

    struct JuryMember {
        bool valid;
        uint256 lastJuryId;
        uint256 disputesApproved;
        uint256 disputesResolved;
    }

    struct DisputeProposal {
        address proposer;
        uint256 juryId;
        bool isApproved;
        uint256 deadline;
    }

    struct Dispute {
        uint256 juryId;
        uint256 deadline;
        bool verdict;
        bool resolved;
    }

    //Jury Events
    event NewLiveJury(uint256 juryId, address[] indexed juryMembers);
    event NewJuryPoolMember(address juryMemeber);
    event RemovedJuryMember(address juryMember);
    event JuryDutyAdded(uint256 indexed juryId, address[] indexed juryMembers);
    event JuryDutyCompleted(uint256 indexed jurydId);
    event Voted(address indexed juryMember, uint256 indexed disputeId, bool decision);

    //Dispute Events
    event NewDispute(uint256 juryId, uint256 disputeId);
    event DisputeDeadlinePostponed(uint256 juryId, uint256 newDeadline);
    event DisputeResolved(bool verdict, uint256 juryId);
    event JuryMemberVoted(bool vote, address indexed juryMember);

    /** MACRO (jury configuraiton) **/

    /**
     * @dev majority rules or unanimous decision
     */
    // function setJuryType() external;

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
