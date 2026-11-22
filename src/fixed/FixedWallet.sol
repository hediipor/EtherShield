// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract FixedWallet {
    address public owner;

    event Transfer(address indexed to, uint256 amount);

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {}

    function transferTo(address payable to, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        require(to != address(0), "zero address");
        emit Transfer(to, amount);
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
