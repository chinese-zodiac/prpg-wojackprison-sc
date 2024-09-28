// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ModifierOnlyExecutor} from "../utils/ModifierOnlyExecutor.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {AccessRoleAdmin} from "../roles/AccessRoleAdmin.sol";
import {IKey} from "../interfaces/IKey.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";

abstract contract DatastoreBase is
    ModifierOnlyExecutor,
    ModifierBlacklisted,
    AccessControlEnumerable,
    AccessRoleAdmin,
    IKey
{
    IExecutor internal immutable X;

    constructor(IExecutor _executor) {
        X = _executor;
        _grantRole(DEFAULT_ADMIN_ROLE, X.globalSettings().governance());
    }
}
