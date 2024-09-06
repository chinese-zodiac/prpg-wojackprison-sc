// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {HasRegionSettings} from "../utils/HasRegionSettings.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {ILocationController} from "../interfaces/ILocationController.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";

abstract contract LocBase is HasRegionSettings, ILocation {
    EnumerableSetAccessControlViewableAddress public validSourceSet;
    EnumerableSetAccessControlViewableAddress public validDestinationSet;
    event OnDeparture(IEntity entity, uint256 entityID, ILocation to);
    event OnArrival(IEntity entity, uint256 entityID, ILocation from);

    error OnlyLocalEntity(IEntity entity, uint256 entityId);
    error OnlyEntityOwner(IEntity entity, uint256 entityId);
    error OnlyLocationController(
        address sender,
        ILocationController locationController
    );

    constructor(
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet
    ) {
        validSourceSet = _validSourceSet;
        validDestinationSet = _validDestinationSet;
    }

    modifier onlyLocationController() {
        if (msg.sender != address(regionSettings.locationController())) {
            revert OnlyLocationController(
                msg.sender,
                regionSettings.locationController()
            );
        }
        _;
    }

    modifier onlyEntityOwner(IEntity entity, uint256 entityId) {
        if (msg.sender != entity.ownerOf(entityId)) {
            revert OnlyEntityOwner(entity, entityId);
        }
        _;
    }

    modifier onlyLocalEntity(IEntity _entity, uint256 _entityId) {
        if (
            address(this) !=
            address(
                regionSettings.locationController().entityIdLocation(
                    _entity,
                    _entityId
                )
            )
        ) {
            revert OnlyLocalEntity(_entity, _entityId);
        }
        _;
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityID,
        ILocation _from
    ) public virtual onlyLocationController {
        validSourceSet.revertIfNotInSet(address(_from));
        regionSettings.validEntitySet().revertIfNotInSet(address(_entity));
        emit OnArrival(_entity, _entityID, _from);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual onlyLocationController {
        validDestinationSet.revertIfNotInSet(address(_to));
        regionSettings.validEntitySet().revertIfNotInSet(address(_entity));
        emit OnDeparture(_entity, _entityID, _to);
    }
}
