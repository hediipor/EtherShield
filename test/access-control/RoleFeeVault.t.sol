// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {RoleFeeVault} from "../../src/fixed/RoleFeeVault.sol";

contract RoleFeeVaultTest is Test {
    RoleFeeVault vault;
    address admin = makeAddr("admin");
    address feeManager = makeAddr("feeManager");
    address treasurer = makeAddr("treasurer");
    address treasury = makeAddr("treasury");
    address hedisarrek = makeAddr("hedisarrek");

    bytes32 FEE;
    bytes32 TREASURY;

    function setUp() public {
        vault = new RoleFeeVault(admin, feeManager, treasurer, treasury);
        FEE = vault.FEE_MANAGER_ROLE();
        TREASURY = vault.TREASURY_ROLE();
    }

    // The exact error OpenZeppelin reverts with
    function _unauthorized(
        address who,
        bytes32 role
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                who,
                role
            );
    }

    // ---------- each role does only its own job ----------

    function test_FeeManagerCanSetFee() public {
        vm.prank(feeManager);
        vault.setFee(500);
        assertEq(vault.feeBps(), 500);
    }

    function test_FeeManagerCannotRedirectFees() public {
        vm.prank(feeManager);
        vm.expectRevert(_unauthorized(feeManager, TREASURY));
        vault.setFeeRecipient(feeManager);
    }

    function test_TreasurerCannotSetFee() public {
        vm.prank(treasurer);
        vm.expectRevert(_unauthorized(treasurer, FEE));
        vault.setFee(500);
    }

    function test_AdminCannotSetFeeDirectly() public {
        vm.prank(admin);
        vm.expectRevert(_unauthorized(admin, FEE));
        vault.setFee(500);
    }

    // ---------- the attacker gets nothing ----------

    function test_Exploit_AttackerCannotSetFee() public {
        vm.prank(hedisarrek);
        vm.expectRevert(_unauthorized(hedisarrek, FEE));
        vault.setFee(1_000);
    }

    function test_Exploit_AttackerCannotGrantHimselfRole() public {
        bytes32 adminRole = vault.DEFAULT_ADMIN_ROLE();
        vm.prank(hedisarrek);
        vm.expectRevert(_unauthorized(hedisarrek, adminRole));
        vault.grantRole(FEE, hedisarrek);
    }

    // ---------- a compromised key can be replaced ----------

    function test_AdminRotatesCompromisedFeeManager() public {
        address newManager = makeAddr("newManager");

        vm.startPrank(admin);
        vault.revokeRole(FEE, feeManager);
        vault.grantRole(FEE, newManager);
        vm.stopPrank();

        vm.prank(feeManager); // old key: rejected
        vm.expectRevert(_unauthorized(feeManager, FEE));
        vault.setFee(500);

        vm.prank(newManager); // new key: works
        vault.setFee(500);
        assertEq(vault.feeBps(), 500);
    }

    function test_HonestWithdraw() public {
        address hedi = makeAddr("hedi");
        vm.deal(hedi, 10 ether);

        vm.prank(hedi);
        vault.deposit{value: 10 ether}();
        vm.prank(hedi);
        vault.withdraw();

        assertEq(hedi.balance, 9.9 ether); // 1% fee
        assertEq(treasury.balance, 0.1 ether);
        assertEq(vault.balances(hedi), 0);
    }
}
