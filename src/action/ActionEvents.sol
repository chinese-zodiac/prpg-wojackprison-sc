// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";

event ActionSuccess(
    address _locCaller,
    uint256 _locId,
    IEntity _entity,
    uint256 _entityID,
    bytes _param
);
