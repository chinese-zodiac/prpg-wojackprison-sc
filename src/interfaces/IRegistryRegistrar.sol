// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IKey} from "../interfaces/IKey.sol";

interface IRegistryRegistrar is IKey {
    function revertIfNotRegistrar(address account) external;
}
