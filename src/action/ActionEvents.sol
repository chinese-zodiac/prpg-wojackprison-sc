// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";

event ActionSuccess(
    address _locCaller,
    ILocation _location,
    IEntity _entity,
    uint256 _entityID,
    bytes _param
);
