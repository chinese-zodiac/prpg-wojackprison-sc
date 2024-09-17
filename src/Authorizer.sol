// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IAuthorizer} from "./interfaces/IAuthorizer.sol";
import {AccessRoleManager} from "./roles/AccessRoleManager.sol";
import {AccessRoleAdmin} from "./roles/AccessRoleAdmin.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract Authorizer is
    IAuthorizer,
    AccessControlEnumerable,
    AccessRoleManager,
    AccessRoleAdmin
{
    function revertIfNotAuthorized(bytes32 role, address account) public view {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }
}
