// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IAuthorizer} from "./interfaces/IAuthorizer.sol";

contract Authorizer is IAuthorizer, AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyAdmin() {
        revertIfNotAuthorized(DEFAULT_ADMIN_ROLE, msg.sender);
        _;
    }

    modifier onlyManager() {
        revertIfNotAuthorized(MANAGER_ROLE, msg.sender);
        _;
    }
    function revertIfNotAuthorized(bytes32 role, address account) public view {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }
}
