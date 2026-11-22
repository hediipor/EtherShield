// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FixedFeeVault} from "../../src/fixed/FixedFeeVault.sol";

contract FixedFeeVaultTest is Test {
    FixedFeeVault vault;
    address treasury = makeAddr("treasury");
    address hedi = makeAddr("hedi");
    address hedisarrek = makeAddr("hedisarrek");

    function setUp() public {
        vault = new FixedFeeVault(treasury); // owner = this test contract
        vm.deal(hedi, 10 ether);
        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
    }

    // ---------- the attack now fails ----------

    function test_Exploit_AttackerCannotSetFee() public {
        vm.prank(hedisarrek);
        vm.expectRevert("not owner");
        vault.setFee(10_000);
    }

    function test_Exploit_AttackerCannotSetRecipient() public {
        vm.prank(hedisarrek);
        vm.expectRevert("not owner");
        vault.setFeeRecipient(hedisarrek);
    }

    // ---------- the owner still works, within limits ----------

    function test_OwnerCanChangeFee() public {
        vault.setFee(500); // 5%
        vm.prank(hedi);
        vault.withdraw();
        assertEq(hedi.balance, 9.5 ether);
        assertEq(treasury.balance, 0.5 ether);
    }

    function test_OwnerCannotExceedCap() public {
        vm.expectRevert("fee too high");
        vault.setFee(20_000);
    }

    function test_OwnerCannotSetZeroRecipient() public {
        vm.expectRevert("zero address");
        vault.setFeeRecipient(address(0));
    }

    // ---------- honest users unaffected ----------

    function test_NormalFee() public {
        vm.prank(hedi);
        vault.withdraw();
        assertEq(hedi.balance, 9.9 ether);
        assertEq(treasury.balance, 0.1 ether);
    }
}
