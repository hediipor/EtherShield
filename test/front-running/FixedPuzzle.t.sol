// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FixedPuzzle} from "../../src/fixed/FixedPuzzle.sol";

contract FixedPuzzleTest is Test {
    FixedPuzzle puzzle;
    address hedi = makeAddr("hedi");
    address hedisarrek = makeAddr("hedisarrek");
    string constant ANSWER = "ethershield";
    bytes32 constant SALT = keccak256("hedi's secret salt");

    function setUp() public {
        puzzle = new FixedPuzzle{value: 10 ether}(
            keccak256(abi.encodePacked(ANSWER))
        );
    }

    function _hediCommits() internal returns (bytes32 c) {
        c = puzzle.getCommitment(ANSWER, hedi, SALT);
        vm.prank(hedi);
        puzzle.commit(c);
    }

    function test_HonestCommitReveal() public {
        _hediCommits();
        vm.roll(block.number + 1);

        vm.prank(hedi);
        puzzle.reveal(ANSWER, SALT);

        assertEq(puzzle.winner(), hedi);
        assertEq(hedi.balance, 10 ether);
    }

    function test_RevealSameBlockFails() public {
        _hediCommits();

        vm.prank(hedi);
        vm.expectRevert("reveal too early");
        puzzle.reveal(ANSWER, SALT);
    }

    function test_Exploit_CopiedCommitmentFails() public {
        bytes32 c = _hediCommits();

        // hedisarrek copies hedi's commitment from the mempool
        vm.prank(hedisarrek);
        puzzle.commit(c);
        vm.roll(block.number + 1);

        // hedi reveals; the bot copies answer + salt and front-runs the reveal
        vm.prank(hedisarrek);
        vm.expectRevert("commitment mismatch"); // hash was made with hedi's address
        puzzle.reveal(ANSWER, SALT);

        vm.prank(hedi);
        puzzle.reveal(ANSWER, SALT);
        assertEq(puzzle.winner(), hedi);
    }

    function test_Exploit_LateCommitFails() public {
        _hediCommits();
        vm.roll(block.number + 1);

        // hedi's reveal is in the mempool; the bot reads the answer and tries
        // to commit + reveal for itself in the same block, ahead of hedi
        bytes32 botSalt = keccak256("bot");
        vm.startPrank(hedisarrek);
        puzzle.commit(puzzle.getCommitment(ANSWER, hedisarrek, botSalt));
        vm.expectRevert("reveal too early");
        puzzle.reveal(ANSWER, botSalt);
        vm.stopPrank();

        // hedi's reveal runs and wins
        vm.prank(hedi);
        puzzle.reveal(ANSWER, SALT);
        assertEq(puzzle.winner(), hedi);
        assertEq(hedisarrek.balance, 0);
    }

    function test_WrongAnswerFails() public {
        bytes32 c = puzzle.getCommitment("wrong", hedi, SALT); // compute first
        vm.prank(hedi);
        puzzle.commit(c); // prank now applies here
        vm.roll(block.number + 1);

        vm.prank(hedi);
        vm.expectRevert("wrong answer");
        puzzle.reveal("wrong", SALT);
    }
}
