// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";

error LocCallerNotEntityOwner(
    address locCaller,
    IEntity entity,
    uint256 entityID
);

error InvalidParamDecoding(bytes param);

error ActionLocked(IEntity _entity, uint256 _entityId, bytes32 _actionKey);
