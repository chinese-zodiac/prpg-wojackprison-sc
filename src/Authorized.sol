// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IAuthorizer} from "./interfaces/IAuthorizer.sol";

//Authorization is chained, so that children contracts
//can check roles with immediate parent if necessary.
//For gas, its recommended for children to check the top node.

contract Authorized is IAuthorizer {
    IAuthorizer public immutable authorizer;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x0;
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(IAuthorizer _authorizer) {
        authorizer = _authorizer;
    }

    modifier onlyAuthorized(bytes32 role) {
        revertIfNotAuthorized(role, msg.sender);
        _;
    }

    modifier onlyAdmin() {
        revertIfNotAuthorized(DEFAULT_ADMIN_ROLE, msg.sender);
        _;
    }

    modifier onlyManager() {
        revertIfNotAuthorized(MANAGER_ROLE, msg.sender);
        _;
    }

    function revertIfNotAuthorized(bytes32 role, address account) public view {
        authorizer.revertIfNotAuthorized(role, account);
    }
}
