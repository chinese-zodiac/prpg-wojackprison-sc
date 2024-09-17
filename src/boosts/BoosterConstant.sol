// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IBooster} from "../interfaces/IBooster.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";

contract BoosterConstant is IBooster {
    uint256 public immutable value;

    constructor(uint256 _value) {
        value = _value;
    }

    function getBoost(
        ILocation,
        IEntity,
        uint256
    ) external view returns (uint256 boost) {
        return value;
    }
}
