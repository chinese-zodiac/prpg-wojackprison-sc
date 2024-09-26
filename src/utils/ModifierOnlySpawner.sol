// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {ISpawner} from "../interfaces/ISpawner.sol";

contract ModifierOnlySpawner {
    error SenderNotSpawner(address sender, ISpawner spawner);

    modifier onlySpawner(ISpawner s) {
        if (msg.sender != address(s)) {
            revert SenderNotSpawner(msg.sender, s);
        }
        _;
    }
}
