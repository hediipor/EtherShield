// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// LAB ONLY: the answer is visible in the mempool before it is mined.
contract VulnerablePuzzle {
    bytes32 public immutable answerHash;
    bool public solved;
    address public winner;

    event Solved(address indexed winner, uint256 prize);

    constructor(bytes32 _answerHash) payable {
        answerHash = _answerHash;
    }

    function solve(string calldata answer) external {
        require(!solved, "already solved");
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
