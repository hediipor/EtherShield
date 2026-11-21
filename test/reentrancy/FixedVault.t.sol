// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FixedVault} from "../../src/fixed/FixedVault.sol"; // ← changed

contract FixedVaultTest is Test {
    FixedVault vault; // ← changed
    address hedi = makeAddr("hedi");

    function setUp() public {
        vault = new FixedVault(); // ← changed
        vm.deal(hedi, 10 ether);
    }

    function test_Deposit() public {
        vm.prank(hedi);
        vault.deposit{value: 3 ether}();

        assertEq(vault.balances(hedi), 3 ether);
        assertEq(address(vault).balance, 3 ether);
        assertEq(hedi.balance, 7 ether);
    }

    function test_Withdraw() public {
        vm.prank(hedi);
        vault.deposit{value: 3 ether}();

        vm.prank(hedi);
        vault.withdraw();

        assertEq(vault.balances(hedi), 0);
        assertEq(hedi.balance, 10 ether);
    }

    function test_WithdrawWithNothing_Reverts() public {
        vm.prank(hedi);
        vm.expectRevert("nothing to withdraw");
        vault.withdraw();
    }
}
