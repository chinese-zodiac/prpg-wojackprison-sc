// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IEntity} from "./IEntity.sol";

interface ISpawner {
    function spawn(
        uint256 _locationID,
        IEntity _entity,
        address _receiver
    ) external;
}
