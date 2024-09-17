// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {EnumerableSetAccessControlViewableUint256} from "../utils/EnumerableSetAccessControlViewableUint256.sol";
import {Authorizer} from "../Authorizer.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {HasRSBlacklist} from "../utils/HasRSBlacklist.sol";

//Permissionless Datastore.
//It allows ONLY the Entity's current Location to move an Entity to a new Location.
//Its Permisionless, since any dev can add their own location just by calling "setup()"
//To move an Entity, it must be moved from the current location
//Devs, to do this you will need to request an existing game to "link out" to you,
//in which case your game will be compatible with an existing gameworld, or
//you will need to spawn your own entities to buid a seperate gameworld.
//Stores data related to movement between locations
contract DatastoreEntityLocation is HasRSBlacklist, Authorizer {
    bytes32 public constant KEY = keccak256("DATASTORE_ENTITY_LOCATION");

    mapping(ILocation location => mapping(IEntity entity => EnumerableSetAccessControlViewableUint256 entityIdSet))
        public locationEntityIdSet;
    mapping(IEntity entity => mapping(uint256 entityID => ILocation location))
        public entityIdLocation;

    error NotEntityLocation(address account, IEntity entity, uint256 entityId);
    error LocationEntityIDSetDoesNotExist(ILocation sender, IEntity entity);
    error AlreadySpawned(IEntity entity, uint256 entityId);
    error AlreadySetup(ILocation location, IEntity entity);

    event Move(
        IEntity entity,
        uint256 entityId,
        ILocation current,
        ILocation destination
    );

    constructor(RegionSettings _rs) HasRSBlacklist(_rs) {
        _grantRole(DEFAULT_ADMIN_ROLE, _rs.governance());
        //For calling locationEntityIdSet
        _grantRole(MANAGER_ROLE, address(this));
    }

    modifier onlyEntityLocation(IEntity _entity, uint256 _entityId) {
        revertIfNotAccountIsEntityLocation(msg.sender, _entity, _entityId);
        _;
    }

    modifier onlyEntityIdSetExists(ILocation _location, IEntity _entity) {
        if (address(locationEntityIdSet[_location][_entity]) == address(0x0)) {
            revert LocationEntityIDSetDoesNotExist(_location, _entity);
        }
        _;
    }

    function revertIfNotAccountIsEntityLocation(
        address _account,
        IEntity _entity,
        uint256 _entityId
    ) public view {
        if (
            _account != address(entityIdLocation[_entity][_entityId]) ||
            _account == address(0x0)
        ) {
            revert NotEntityLocation(_account, _entity, _entityId);
        }
    }

    //Spawns an entity at location, so it can move in the future.
    function spawn(
        IEntity _entity,
        uint256 _entityId,
        ILocation _dest
    )
        external
        onlyEntityLocation(_entity, _entityId)
        blacklistedEntity(_entity, _entityId)
    {
        if (entityIdLocation[_entity][_entityId] != ILocation(address(0x0))) {
            revert AlreadySpawned(_entity, _entityId);
        }
        _add(_entity, _entityId, _dest);
        emit Move(_entity, _entityId, ILocation(address(0x0)), _dest);
    }

    function setup(ILocation location, IEntity entity) external {
        if (address(locationEntityIdSet[location][entity]) != address(0x0)) {
            revert AlreadySetup(location, entity);
        }
        locationEntityIdSet[location][
            entity
        ] = new EnumerableSetAccessControlViewableUint256(this);
    }

    //Despawns an entity at location, so it leaves the game.
    function despawn(
        IEntity _entity,
        uint256 _entityId,
        ILocation _curr
    )
        external
        onlyEntityLocation(_entity, _entityId)
        blacklistedEntity(_entity, _entityId)
    {
        _del(_entity, _entityId, _curr);
        emit Move(_entity, _entityId, _curr, ILocation(address(0x0)));
    }

    //Moves an entity to a new location.
    function move(
        IEntity _entity,
        uint256 _entityId,
        ILocation _dest
    )
        external
        onlyEntityLocation(_entity, _entityId)
        blacklistedEntity(_entity, _entityId)
    {
        ILocation curr = entityIdLocation[_entity][_entityId];
        _tfr(_entity, _entityId, curr, _dest);
        emit Move(_entity, _entityId, curr, _dest);
    }

    function _add(
        IEntity _entity,
        uint256 _entityId,
        ILocation _dest
    ) internal onlyEntityIdSetExists(_dest, _entity) {
        locationEntityIdSet[_dest][_entity].add(_entityId);
        entityIdLocation[_entity][_entityId] = _dest;
    }

    function _del(
        IEntity _entity,
        uint256 _entityId,
        ILocation _curr
    ) internal {
        locationEntityIdSet[_curr][_entity].remove(_entityId);
        delete entityIdLocation[_entity][_entityId];
    }

    function _tfr(
        IEntity _entity,
        uint256 _entityId,
        ILocation _curr,
        ILocation _dest
    ) internal onlyEntityIdSetExists(_curr, _entity) {
        locationEntityIdSet[_curr][_entity].remove(_entityId);
        _add(_entity, _entityId, _dest);
    }
}
