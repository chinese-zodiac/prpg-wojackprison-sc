// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";

error LocCallerNotEntityOwner(
    address locCaller,
    IEntity entity,
    uint256 entityID
);
error SenderNotLocation(address sender, ILocation location);

error InvalidParamDecoding(bytes param);

error ActionLocked(IEntity _entity, uint256 _entityId, bytes32 _actionKey);
