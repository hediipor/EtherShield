// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// LAB ONLY: signed vouchers can be replayed.
contract VulnerableSigVault {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Claimed(address indexed from, address indexed to, uint256 amount);

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// Anyone can submit a voucher signed by `from`.
    function claim(
        address from,
        address payable to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(abi.encodePacked(from, to, amount));
        address signer = ecrecover(digest, v, r, s);
        require(signer == from, "bad signature");
        require(balances[from] >= amount, "insufficient balance");

        balances[from] -= amount;
        emit Claimed(from, to, amount);

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
