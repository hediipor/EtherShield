// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FixedSigVault {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces; // next unused voucher number per signer

    event Deposit(address indexed user, uint256 amount);
    event Claimed(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /// The exact message a signer must sign: bound to this vault, this chain and one nonce.
    function getDigest(
        address from,
        address to,
        uint256 amount,
        uint256 nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    block.chainid,
                    from,
                    to,
                    amount,
                    nonce
                )
            );
    }

    function claim(
        address from,
        address payable to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[from];
        address signer = ECDSA.recover(
            getDigest(from, to, amount, nonce),
            v,
            r,
            s
        );
        require(signer == from, "bad signature");
        require(balances[from] >= amount, "insufficient balance");

        nonces[from] = nonce + 1; // Effect: this voucher can never be used again
        balances[from] -= amount;
        emit Claimed(from, to, amount, nonce);

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
