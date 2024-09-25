// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {Executor} from "../Executor.sol";
import {IEntity} from "../interfaces/IEntity.sol";

contract ModifierBlacklisted {
    modifier blacklisted(Executor x, address account) {
        x.revertIfAccountBlacklisted(account);
        _;
    }
    modifier blacklistedEntity(
        Executor x,
        IEntity entity,
        uint256 entityID
    ) {
        x.revertIfEntityOwnerBlacklisted(entity, entityID);
    }
}