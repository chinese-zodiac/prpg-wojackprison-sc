// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";
import {EnumerableSetAccessControlViewableUint256} from "./utils/EnumerableSetAccessControlViewableUint256.sol";

//Permisionless LocationController
//Anyone can implement ILocation and then allow users to init/move entities using this controller.
//Allows the location to be looked up for entitites, so location based logic is possible for games with locations.
contract LocationController is ILocationController {
    mapping(ILocation location => mapping(IEntity entity => EnumerableSetAccessControlViewableUint256 entityIdSet))
        public locationEntityIdSet;
    mapping(IEntity entity => mapping(uint256 entityID => ILocation location))
        public entityIdLocation;

    error InvalidDestination(
        IEntity entity,
        uint256 entityID,
        ILocation current,
        ILocation destination
    );
    error MoveFailed(
        IEntity entity,
        uint256 entityID,
        ILocation current,
        ILocation destination
    );
    error AlreadySpawned(
        IEntity entity,
        uint256 entityID,
        ILocation current,
        ILocation destination
    );
    error NotSpawned(
        IEntity entity,
        uint256 entityID,
        ILocation current,
        ILocation destination
    );

    modifier onlyEntityOwner(IEntity _entity, uint256 _entityId) {
        require(msg.sender == _entity.ownerOf(_entityId), "Only entity owner");
        _;
    }

    event Move(IEntity entity, uint256 entityID, ILocation from, ILocation to);
    //Moves entity from current location to new location.
    //First updates the entity's location, then calls arrival/departure hooks.
    function move(
        IEntity _entity,
        uint256 _entityId,
        ILocation _dest
    ) external onlyEntityOwner(_entity, _entityId) {
        ILocation _prev = entityIdLocation[_entity][_entityId];
        if (_prev == _dest) {
            revert InvalidDestination(_entity, _entityId, _prev, _dest);
        }

        _prev.LOCATION_CONTROLLER_onDeparture(_entity, _entityId, _dest);
        locationEntityIdSet[_prev][_entity].remove(_entityId);
        locationEntityIdSet[_dest][_entity].add(_entityId);
        entityIdLocation[_entity][_entityId] = _dest;
        _dest.LOCATION_CONTROLLER_onArrival(_entity, _entityId, _prev);

        if (
            locationEntityIdSet[_prev][_entity].getContains(_entityId) ||
            !locationEntityIdSet[_dest][_entity].getContains(_entityId)
        ) {
            revert MoveFailed(_entity, _entityId, _prev, _dest);
        }

        emit Move(_entity, _entityId, _prev, _dest);
    }

    //Spawns an entity at location, so it can move in the future.
    function spawn(
        IEntity _entity,
        uint256 _entityId,
        ILocation _to
    ) external onlyEntityOwner(_entity, _entityId) {
        if (entityIdLocation[_entity][_entityId] != ILocation(address(0x0))) {
            revert AlreadySpawned(
                _entity,
                _entityId,
                ILocation(address(0x0)),
                _to
            );
        }
        entityIdLocation[_entity][_entityId] = _to;
        if (!locationEntityIdSet[_to][_entity].getContains(_entityId)) {
            revert MoveFailed(_entity, _entityId, ILocation(address(0x0)), _to);
        }
        emit Move(_entity, _entityId, ILocation(address(0x0)), _to);
        _to.LOCATION_CONTROLLER_onArrival(
            _entity,
            _entityId,
            ILocation(address(0x0))
        );
    }

    //despawns an entity, so it is no longer tracked as at a specific location.
    function despawn(
        IEntity _entity,
        uint256 _entityId
    ) external onlyEntityOwner(_entity, _entityId) {
        ILocation _prev = entityIdLocation[_entity][_entityId];
        if (_prev == ILocation(address(0x0))) {
            revert NotSpawned(
                _entity,
                _entityId,
                _prev,
                ILocation(address(0x0))
            );
        }

        emit Move(_entity, _entityId, _prev, ILocation(address(0x0)));
        _prev.LOCATION_CONTROLLER_onDeparture(
            _entity,
            _entityId,
            ILocation(address(0x0))
        );
        delete entityIdLocation[_entity][_entityId];
        if (locationEntityIdSet[_prev][_entity].getContains(_entityId)) {
            revert MoveFailed(
                _entity,
                _entityId,
                _prev,
                ILocation(address(0x0))
            );
        }
    }
}
