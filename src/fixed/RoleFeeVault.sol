// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleFeeVault is AccessControl {
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    uint256 public constant MAX_FEE_BPS = 1_000; // 10%

    address public feeRecipient;
    uint256 public feeBps;
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 payout, uint256 fee);
    event FeeChanged(uint256 newFeeBps);
    event FeeRecipientChanged(address newRecipient);

    constructor(
        address admin,
        address feeManager,
        address treasuryManager,
        address _feeRecipient
    ) {
        require(_feeRecipient != address(0), "zero address");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEE_MANAGER_ROLE, feeManager);
        _grantRole(TREASURY_ROLE, treasuryManager);
        feeRecipient = _feeRecipient;
        feeBps = 100;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "nothing to withdraw");

        balances[msg.sender] = 0; // CEI: lesson from bug #1
        uint256 fee = (amount * feeBps) / 10_000;
        uint256 payout = amount - fee;
        emit Withdraw(msg.sender, payout, fee);

        (bool ok1, ) = feeRecipient.call{value: fee}("");
        require(ok1, "fee transfer failed");
        (bool ok2, ) = msg.sender.call{value: payout}("");
        require(ok2, "payout failed");
    }

    function setFee(uint256 newFeeBps) external onlyRole(FEE_MANAGER_ROLE) {
        require(newFeeBps <= MAX_FEE_BPS, "fee too high");
        feeBps = newFeeBps;
        emit FeeChanged(newFeeBps);
    }

    function setFeeRecipient(
        address newRecipient
    ) external onlyRole(TREASURY_ROLE) {
        require(newRecipient != address(0), "zero address");
        feeRecipient = newRecipient;
        emit FeeRecipientChanged(newRecipient);
    }
}
