// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {RegistryBase} from "./RegistryBase.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {IKey} from "../interfaces/IKey.sol";

contract RegistryDatastore is RegistryBase, IKey {
    bytes32 public constant KEY = keccak256("REGISTRY_DATASTORE");

    constructor(RegionSettings _rs) RegistryBase(_rs) {}
}
