// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {VulnerableVault} from "../../src/vulnerable/VulnerableVault.sol";

contract VaultTest is Test {
    VulnerableVault vault;
    address hedi = makeAddr("hedi");

    function setUp() public {
        vault = new VulnerableVault(); // deploy a fresh vault
        vm.deal(hedi, 10 ether); // give hedi 10 ETH
    }

    function test_Deposit() public {
        vm.prank(hedi);
        vault.deposit{value: 3 ether}();

        assertEq(vault.balances(hedi), 3 ether); // vault's records
        assertEq(address(vault).balance, 3 ether); // real ETH in the vault
        assertEq(hedi.balance, 7 ether); // hedi paid 3
    }

    function test_Withdraw() public {
        vm.prank(hedi);
        vault.deposit{value: 3 ether}();

        vm.prank(hedi);
        vault.withdraw();

        assertEq(vault.balances(hedi), 0);
        assertEq(hedi.balance, 10 ether); // got everything back
    }

    function test_WithdrawWithNothing_Reverts() public {
        vm.prank(hedi);
        vm.expectRevert("nothing to withdraw");
        vault.withdraw();
    }
}
