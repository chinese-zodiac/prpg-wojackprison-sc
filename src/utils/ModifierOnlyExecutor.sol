// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IExecutor} from "../interfaces/IExecutor.sol";

contract ModifierOnlyExecutor {
    error SenderNotExecutor(address sender, IExecutor executor);

    modifier onlyExecutor(IExecutor x) {
        if (msg.sender != address(x)) {
            revert SenderNotExecutor(msg.sender, x);
        }
        _;
    }
}
