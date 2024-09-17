// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ManagerRole} from "./ManagerRole.sol";

contract AccessRoleManager is ManagerRole, AccessControlEnumerable {
    modifier onlyManager() {
        _checkRole(MANAGER_ROLE);
        _;
    }
}
