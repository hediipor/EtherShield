// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VulnerableWallet} from "../../src/vulnerable/VulnerableWallet.sol";
import {PhishingAttacker, IWallet} from "../../src/attackers/PhishingAttacker.sol";

contract TxOriginTest is Test {
    VulnerableWallet wallet;
    address hedi = makeAddr("hedi");
    address hedisarrek = makeAddr("hedisarrek");
    address hedi2 = makeAddr("hedi2");

    function setUp() public {
        vm.deal(hedi, 10 ether);
        vm.prank(hedi, hedi);
        wallet = new VulnerableWallet{value: 10 ether}(); // hedi owns a 10 ETH wallet
    }

    function test_OwnerCanTransfer() public {
        vm.prank(hedi, hedi);
        wallet.transferTo(payable(hedi2), 1 ether);
        assertEq(hedi2.balance, 1 ether);
    }

    function test_StrangerCannotTransferDirectly() public {
        vm.prank(hedisarrek, hedisarrek);
        vm.expectRevert("not owner");
        wallet.transferTo(payable(hedisarrek), 1 ether);
    }

    function test_Exploit_PhishingDrainsWallet() public {
        // hedisarrek deploys the bait
        vm.prank(hedisarrek);
        PhishingAttacker bait = new PhishingAttacker(IWallet(address(wallet)));

        // hedi is tricked into "claiming a reward"
        vm.prank(hedi, hedi);
        bait.claimReward();

        console.log("wallet balance (ETH):", address(wallet).balance / 1 ether);
        console.log("hedisarrek balance (ETH):", hedisarrek.balance / 1 ether);

        assertEq(address(wallet).balance, 0);
        assertEq(hedisarrek.balance, 10 ether);
    }
}
