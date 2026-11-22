// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// LAB ONLY: authenticates with tx.origin.
contract VulnerableWallet {
    address public owner;

    event Transfer(address indexed to, uint256 amount);

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    function transferTo(address payable to, uint256 amount) external {
        require(tx.origin == owner, "not owner");
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
        emit Transfer(to, amount);
    }
}
