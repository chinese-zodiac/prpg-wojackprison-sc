// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {Executor} from "../Executor.sol";

contract ModifierOnlyExecutor {
    error SenderNotExecutor(account sender, Executor executor);

    modifier onlyExecutor(Executor x) {
        if (msg.sender != address(x)) {
            revert SenderNotExecutor(msg.sender, x);
        }
        _;
    }
}
