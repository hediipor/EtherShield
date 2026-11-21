// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VulnerableVault} from "../../src/vulnerable/VulnerableVault.sol";
import {ReentrancyAttacker, IVault} from "../../src/attackers/ReentrancyAttacker.sol";
import {FixedVault} from "../../src/fixed/FixedVault.sol";

contract ReentrancyTest is Test {
    address hedi = makeAddr("hedi");
    address hedi2 = makeAddr("hedi2");
    address hedisarrek = makeAddr("hedisarrek"); // the attacker

    function test_Exploit_DrainsVulnerableVault() public {
        // 1. Setup: two honest users deposit 10 ETH each
        VulnerableVault vault = new VulnerableVault();
        vm.deal(hedi, 10 ether);
        vm.deal(hedi2, 10 ether);
        vm.deal(hedisarrek, 1 ether);

        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
        vm.prank(hedi2);
        vault.deposit{value: 10 ether}();
        assertEq(address(vault).balance, 20 ether);

        // 2. Attack: hedisarrek deploys her contract and attacks with 1 ETH
        vm.startPrank(hedisarrek);
        ReentrancyAttacker attacker = new ReentrancyAttacker(IVault(address(vault)));
        attacker.attack{value: 1 ether}();
        attacker.loot();
        vm.stopPrank();

        console.log("re-entries:", attacker.reentries());
        console.log("hedisarrek balance (ETH):", hedisarrek.balance / 1 ether);

        // 3. Prove the damage
        assertEq(address(vault).balance, 0); // vault is empty
        assertEq(hedisarrek.balance, 21 ether); // hedisarrek turned 1 ETH into 21
        assertEq(vault.balances(hedi), 10 ether); // records still say hedi owns 10!
    }

    function test_Exploit_FailsOnFixedVault() public {
        FixedVault vault = new FixedVault();
        vm.deal(hedi, 10 ether);
        vm.deal(hedi2, 10 ether);
        vm.deal(hedisarrek, 1 ether);

        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
        vm.prank(hedi2);
        vault.deposit{value: 10 ether}();

        vm.startPrank(hedisarrek);
        ReentrancyAttacker attacker = new ReentrancyAttacker(IVault(address(vault)));
        vm.expectRevert(); // the attack must fail
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        assertEq(address(vault).balance, 20 ether); // hedi and hedi2's money is safe
        assertEq(hedisarrek.balance, 1 ether); // hedisarrek didn't even lose her stake
    }
}
