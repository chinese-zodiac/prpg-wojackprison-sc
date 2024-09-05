// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {ILocation} from "./interfaces/ILocation.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";

contract LocationBase is ILocation, AccessControlEnumerable {
    ILocationController immutable locationController;

    EnumerableSetAccessControlViewableAddress public validSourceSet;
    EnumerableSetAccessControlViewableAddress public validDestinationSet;
    EnumerableSetAccessControlViewableAddress public validEntitySet;

    event OnDeparture(IEntity entity, uint256 entityID, ILocation to);
    event OnArrival(IEntity entity, uint256 entityID, ILocation from);

    error OnlyLocalEntity(IEntity entity, uint256 entityId);
    error OnlyEntityOwner(IEntity entity, uint256 entityId);
    error OnlyLocationController(
        address sender,
        ILocationController locationController
    );

    constructor(
        ILocationController _locationController,
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet,
        EnumerableSetAccessControlViewableAddress _validEntitySet
    ) {
        locationController = _locationController;
        validSourceSet = _validSourceSet;
        validDestinationSet = _validDestinationSet;
        validEntitySet = _validEntitySet;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyLocationController() {
        if (msg.sender != address(locationController)) {
            revert OnlyLocationController(msg.sender, locationController);
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
            address(locationController.entityIdLocation(_entity, _entityId))
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
        validEntitySet.revertIfNotInSet(address(_entity));
        emit OnArrival(_entity, _entityID, _from);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual onlyLocationController {
        validDestinationSet.revertIfNotInSet(address(_to));
        validEntitySet.revertIfNotInSet(address(_entity));
        emit OnDeparture(_entity, _entityID, _to);
    }
}
