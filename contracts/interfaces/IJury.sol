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
    event NewLiveJury(uint256 juryId, uint256[] indexed juryMembers, uint256 expiration);
    event NewJuryPoolMember(address indexed juryMember, uint256 indexed jurorId);

    // add and remove probably an afterthought right now for time sake
    // event RemovedJuryMember(address indexed juryMember, uint256 indexed jurorId);
    event JuryDutyAdded(uint256 indexed juryId, uint256[] indexed juryMembers);
    event JuryDutyCompleted(uint256 indexed juryId);
    event Voted(uint256 indexed jurorId, uint256 indexed disputeId, bool decision);

    //Dispute Events
    event NewDisputeProposal(
        address indexed proposer,
        uint256 indexed juryId,
        uint256 indexed proposedId,
        uint256 deadline
    );

    event ProposalPassed(uint256 indexed proposedId, uint256 indexed jurorId);
    event NewDispute(uint256 indexed juryId, uint256 indexed disputeId, uint256 deadline);
    event DisputeDeadlinePostponed(uint256 indexed disputeId, uint256 newDeadline);
    event DisputeResolved(uint256 indexed disputeId, bool verdict);

    function newDisputeProposal(uint256 _deadline) external;

    function approveDisputeProposal(uint256 _disputeProposalId) external;

    function extendDisputeDeadline(uint256 _disputeId) external;

    function vote(uint256 _disputeId, bool _vote) external;

    // function addJuryPoolMember(address _newMember) external;
}
