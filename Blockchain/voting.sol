// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

contract Ballot {
    // Struct to store voter data
    struct Voter {
        uint weight;
        bool voted;
        uint vote;
    }
    // Struct to store proposal vote count
    struct Proposal {
        uint voteCount;
    }

    // Address of the chairperson who can give the right to vote
    address public chairperson;

    // Mappings to store voter data and whether they have voted
    mapping(address => Voter) public voters;
    mapping(address => bool) public hasVoted;

    // Array of proposals
    Proposal[] public proposals;

    // Events to emit when a new voter is registered, a vote is cast, or an irregularity is detected
    event VoterRegistered(address voter);
    event Voted(address voter, uint proposal);
    event IrregularityDetected(address indexed voter, string message);

    // Constructor to initialize the chairperson and proposals
    constructor(uint numProposals) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        // Initialize proposals with vote count of 0
        for (uint i = 0; i < numProposals; i++) {
            proposals.push(Proposal(0));
        }
    }

    // Function to give the right to vote to a new voter
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(!hasVoted[voter], "Already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
        voters[voter].voted = false;
        emit VoterRegistered(voter);
    }

    // Function to allow a voter to cast their vote for a particular proposal
    function vote(uint proposal, address voter) public {
        // Get the voter's data
        Voter storage sender = voters[voter];
        // Check if the voter has the right to vote
        require(sender.weight != 0, "Has no right to vote");
        // Check if the voter has already voted
        require(!sender.voted, "Already voted.");
        require(!hasVoted[voter], "Already voted.");
        // Update the voter's data to indicate that they have voted for the proposal
        sender.voted = true;
        sender.vote = proposal;
        hasVoted[voter] = true;
        // Update the proposal's vote count
        proposals[proposal].voteCount += sender.weight;
        // Emit the Voted event
        emit Voted(voter, proposal);
    }

    // Function to determine the index of the winning proposal
    function winningProposal() public
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        // Iterate through the proposals to find the one with the highest vote count
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
        // Check for ties and emit the IrregularityDetected event if a tie is detected
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount == winningVoteCount && p != winningProposal_) {
                emit IrregularityDetected(msg.sender, "Tie detected.");
            }
        }
    }

    // Function to return the vote count for the winning proposal
    function winnerName() public
            returns (bytes32 winnerName_)
    {
        // Convert the winning vote count to bytes32 and return it
        winnerName_ = bytes32(proposals[winningProposal()].voteCount);
    }
}
