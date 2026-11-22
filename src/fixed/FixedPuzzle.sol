// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract FixedPuzzle {
    struct Commitment {
        bytes32 hash;
        uint256 blockNumber;
    }

    bytes32 public immutable answerHash;
    bool public solved;
    address public winner;
    mapping(address => Commitment) public commitments;

    event Committed(address indexed solver);
    event Solved(address indexed winner, uint256 prize);

    constructor(bytes32 _answerHash) payable {
        answerHash = _answerHash;
    }

    /// Helper for solvers: what to commit to.
    function getCommitment(
        string calldata answer,
        address solver,
        bytes32 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(answer, solver, salt));
    }

    /// Step 1: commit without revealing anything.
    function commit(bytes32 commitment) external {
        require(!solved, "already solved");
        commitments[msg.sender] = Commitment(commitment, block.number);
        emit Committed(msg.sender);
    }

    /// Step 2: reveal, at least one block after committing.
    function reveal(string calldata answer, bytes32 salt) external {
        require(!solved, "already solved");
        Commitment memory c = commitments[msg.sender];
        require(c.hash != bytes32(0), "no commitment");
        require(block.number > c.blockNumber, "reveal too early");
        require(
            c.hash == getCommitment(answer, msg.sender, salt),
            "commitment mismatch"
        );
        require(
            keccak256(abi.encodePacked(answer)) == answerHash,
            "wrong answer"
        );

        solved = true;
        winner = msg.sender;
        uint256 prize = address(this).balance;
        emit Solved(msg.sender, prize);

        (bool ok, ) = msg.sender.call{value: prize}("");
        require(ok, "transfer failed");
    }
}
