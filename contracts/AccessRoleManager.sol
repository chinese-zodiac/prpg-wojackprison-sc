// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract AccessRoleManager is AccessControlEnumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    modifier onlyManager() {
        _checkRole(MANAGER_ROLE);
        _;
    }
}
