// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {FixedSigVault} from "../../src/fixed/FixedSigVault.sol";

contract FixedSigVaultTest is Test {
    FixedSigVault vault;
    address hedi;
    uint256 hediKey;
    address payable hedi2 = payable(makeAddr("hedi2"));

    function setUp() public {
        (hedi, hediKey) = makeAddrAndKey("hedi");
        vault = new FixedSigVault();
        vm.deal(hedi, 10 ether);
        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
    }

    // hedi signs a voucher for a given vault and nonce, using the vault's own digest
    function _sign(
        FixedSigVault v_,
        address to,
        uint256 amount,
        uint256 nonce
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        (v, r, s) = vm.sign(hediKey, v_.getDigest(hedi, to, amount, nonce));
    }

    function test_HonestClaim() public {
        (uint8 v, bytes32 r, bytes32 s) = _sign(vault, hedi2, 1 ether, 0);
        vault.claim(hedi, hedi2, 1 ether, v, r, s);

        assertEq(hedi2.balance, 1 ether);
        assertEq(vault.nonces(hedi), 1);
    }

    function test_Exploit_ReplayFails() public {
        (uint8 v, bytes32 r, bytes32 s) = _sign(vault, hedi2, 1 ether, 0);
        vault.claim(hedi, hedi2, 1 ether, v, r, s); // first use: OK

        vm.expectRevert("bad signature");
        vault.claim(hedi, hedi2, 1 ether, v, r, s); // replay: rejected

        assertEq(hedi2.balance, 1 ether);
        assertEq(vault.balances(hedi), 9 ether);
    }

    function test_Exploit_CrossVaultReplayFails() public {
        FixedSigVault vault2 = new FixedSigVault();
        vm.deal(hedi, 10 ether);
        vm.prank(hedi);
        vault2.deposit{value: 10 ether}();

        (uint8 v, bytes32 r, bytes32 s) = _sign(vault, hedi2, 1 ether, 0); // signed for vault 1

        vm.expectRevert("bad signature");
        vault2.claim(hedi, hedi2, 1 ether, v, r, s);
    }

    function test_Exploit_CrossChainReplayFails() public {
        (uint8 v, bytes32 r, bytes32 s) = _sign(vault, hedi2, 1 ether, 0); // signed on chain 31337

        vm.chainId(1); // now "on mainnet"
        vm.expectRevert("bad signature");
        vault.claim(hedi, hedi2, 1 ether, v, r, s);
    }

    function test_SequentialVouchers() public {
        (uint8 v0, bytes32 r0, bytes32 s0) = _sign(vault, hedi2, 1 ether, 0);
        (uint8 v1, bytes32 r1, bytes32 s1) = _sign(vault, hedi2, 2 ether, 1);

        vault.claim(hedi, hedi2, 1 ether, v0, r0, s0);
        vault.claim(hedi, hedi2, 2 ether, v1, r1, s1);

        assertEq(hedi2.balance, 3 ether);
        assertEq(vault.nonces(hedi), 2);
    }
}
