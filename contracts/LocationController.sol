// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IEntity.sol";
import "./interfaces/ILocation.sol";
import "./interfaces/ILocationController.sol";

//Permisionless LocationController
//Anyone can implement ILocation and then allow users to init/move entities using this controller.
//Allows the location to be looked up for entitites, so location based logic is possible for games with locations.
contract LocationController is ILocationController {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(ILocation => mapping(IEntity => EnumerableSet.UintSet)) locationEntitiesIndex;
    mapping(IEntity => mapping(uint256 => ILocation)) entityLocation;

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
        ILocation _prev = entityLocation[_entity][_entityId];
        require(_prev != _dest, "Cannot move to current location");
        entityLocation[_entity][_entityId] = _dest;
        require(
            locationEntitiesIndex[_prev][_entity].remove(_entityId),
            "Remove failed"
        );
        require(
            locationEntitiesIndex[_dest][_entity].add(_entityId),
            "Add failed"
        );

        emit Move(_entity, _entityId, _prev, _dest);
        _prev.LOCATION_CONTROLLER_onDeparture(_entity, _entityId, _dest);
        _dest.LOCATION_CONTROLLER_onArrival(_entity, _entityId, _prev);
    }

    //Spawns an entity at location, so it can move in the future.
    function spawn(
        IEntity _entity,
        uint256 _entityId,
        ILocation _to
    ) external onlyEntityOwner(_entity, _entityId) {
        require(
            entityLocation[_entity][_entityId] == ILocation(address(0x0)),
            "Entity already spawned"
        );
        entityLocation[_entity][_entityId] = _to;
        require(
            locationEntitiesIndex[_to][_entity].add(_entityId),
            "Add failed"
        );
        _to.LOCATION_CONTROLLER_onArrival(
            _entity,
            _entityId,
            ILocation(address(0x0))
        );
        emit Move(_entity, _entityId, ILocation(address(0x0)), _to);
    }

    //despawns an entity, so it is no longer tracked as at a specific location.
    function despawn(
        IEntity _entity,
        uint256 _entityId
    ) external onlyEntityOwner(_entity, _entityId) {
        require(
            entityLocation[_entity][_entityId] != ILocation(address(0x0)),
            "Entity not spawned"
        );
        ILocation _prev = entityLocation[_entity][_entityId];
        delete entityLocation[_entity][_entityId];
        require(
            locationEntitiesIndex[_prev][_entity].remove(_entityId),
            "Remove failed"
        );

        _prev.LOCATION_CONTROLLER_onDeparture(
            _entity,
            _entityId,
            ILocation(address(0x0))
        );
        emit Move(_entity, _entityId, _prev, ILocation(address(0x0)));
    }

    //High gas usage, view only
    function viewOnly_getAllLocalEntitiesFor(
        ILocation _location,
        IEntity _entity
    ) external view override returns (uint256[] memory entityIds_) {
        entityIds_ = locationEntitiesIndex[_location][_entity].values();
    }

    function getEntityLocation(
        IEntity _entity,
        uint256 _entityId
    ) public view override returns (ILocation) {
        return entityLocation[_entity][_entityId];
    }

    function getLocalEntityCountFor(
        ILocation _location,
        IEntity _entity
    ) public view override returns (uint256) {
        return locationEntitiesIndex[_location][_entity].length();
    }

    function getLocalEntityAtIndexFor(
        ILocation _location,
        IEntity _entity,
        uint256 _i
    ) public view override returns (uint256 entityId_) {
        entityId_ = locationEntitiesIndex[_location][_entity].at(_i);
    }
}
