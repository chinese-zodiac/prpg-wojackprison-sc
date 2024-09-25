// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {Spawner} from "../Spawner.sol";

contract ModifierOnlySpawner {
    error SenderNotSpawner(account sender, Spawner spawner);

    modifier onlySpawner(Spawner s) {
        if (msg.sender != address(s)) {
            revert SenderNotSpawner(msg.sender, s);
        }
        _;
    }
}
