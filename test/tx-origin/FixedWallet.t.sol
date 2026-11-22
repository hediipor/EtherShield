// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FixedWallet} from "../../src/fixed/FixedWallet.sol";
import {PhishingAttacker, IWallet} from "../../src/attackers/PhishingAttacker.sol";

contract FixedWalletTest is Test {
    FixedWallet wallet;
    address hedi = makeAddr("hedi");
    address hedi2 = makeAddr("hedi2");
    address hedisarrek = makeAddr("hedisarrek");

    function setUp() public {
        vm.deal(hedi, 10 ether);
        vm.prank(hedi, hedi);
        wallet = new FixedWallet{value: 10 ether}();
    }

    function test_OwnerCanTransfer() public {
        vm.prank(hedi, hedi);
        wallet.transferTo(payable(hedi2), 1 ether);
        assertEq(hedi2.balance, 1 ether);
    }

    function test_Exploit_PhishingFails() public {
        vm.prank(hedisarrek);
        PhishingAttacker bait = new PhishingAttacker(IWallet(address(wallet)));

        vm.prank(hedi, hedi);
        vm.expectRevert("not owner");
        bait.claimReward();

        assertEq(address(wallet).balance, 10 ether); // hedi's money is safe
        assertEq(hedisarrek.balance, 0);
    }

    function test_CannotSendToZeroAddress() public {
        vm.prank(hedi, hedi);
        vm.expectRevert("zero address");
        wallet.transferTo(payable(address(0)), 1 ether);
    }
}
