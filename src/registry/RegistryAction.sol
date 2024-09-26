// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {Executor} from "../Executor.sol";
import {RegistryBase} from "./RegistryBase.sol";
import {IKey} from "../interfaces/IKey.sol";

contract RegistryAction is RegistryBase, IKey {
    bytes32 public constant KEY = keccak256("REGISTRY_ACTION");

    constructor(Executor _executor) RegistryBase(_executor) {}
}
