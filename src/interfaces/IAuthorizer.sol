// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

interface IAuthorizer {
    function revertIfNotAuthorized(bytes32 role, address account) external view;
}
