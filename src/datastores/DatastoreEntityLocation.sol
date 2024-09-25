// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IEntity} from "../interfaces/IEntity.sol";
import {EnumerableSetAccessControlViewableUint256} from "../utils/EnumerableSetAccessControlViewableUint256.sol";
import {Authorizer} from "../Authorizer.sol";
import {ModifierOnlyExecutor} from "../utils/ModifierOnlyExecutor.sol";
import {ModifierOnlySpawner} from "../utils/ModifierOnlySpawner.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {Executor} from "../Executor.sol";

//Permissionless Datastore.
//It allows ONLY the Entity's current Location to move an Entity to a new Location.
//Its Permisionless, since any dev can add their own location just by calling "setup()"
//To move an Entity, it must be moved from the current location
//Devs, to do this you will need to request an existing game to "link out" to you,
//in which case your game will be compatible with an existing gameworld, or
//you will need to spawn your own entities to buid a seperate gameworld.
//Stores data related to movement between locations
contract DatastoreEntityLocation is
    ModifierBlacklisted,
    ModifierOnlyExecutor,
    ModifierOnlySpawner,
    Authorizer
{
    bytes32 public constant KEY = keccak256("DATASTORE_ENTITY_LOCATION");

    Executor internal immutable X;
    Spawner internal immutable S;
    IEntity public immutable ADMIN_CHARACTER;

    mapping(uint256 locationID => mapping(IEntity entity => EnumerableSetAccessControlViewableUint256 entityIdSet))
        public locationEntityIdSet;
    mapping(IEntity entity => mapping(uint256 entityID => uint256 locationID))
        public entityLocation;

    error NotEntityLocation(
        uint256 locationID,
        IEntity entity,
        uint256 entityId
    );
    error LocationEntityIDSetDoesNotExist(uint256 locationID, IEntity entity);
    error AlreadySpawned(IEntity entity, uint256 entityId);
    error AlreadySetup(uint256 locationID, IEntity entity);

    event Move(
        IEntity entity,
        uint256 entityId,
        uint256 locCurrID,
        uint256 locDestID
    );

    constructor(Executor _executor, Spawner _spawner, IEntity _adminCharacter) {
        X = _executor;
        S = _spawner;
        _grantRole(DEFAULT_ADMIN_ROLE, X.regionSettings().governance());
        //For calling locationEntityIdSet
        _grantRole(MANAGER_ROLE, address(this));
        ADMIN_CHARACTER = _adminCharacter;
    }

    modifier onlyEntityIdSetExists(uint256 _locationID, IEntity _entity) {
        if (
            address(locationEntityIdSet[_locationID][_entity]) == address(0x0)
        ) {
            revert LocationEntityIDSetDoesNotExist(_locationID, _entity);
        }
        _;
    }

    //Spawns an entity at location, so it can move in the future.
    function spawn(
        IEntity _entity,
        uint256 _entityId,
        uint256 _locationId
    ) external onlySpawner(S) blacklistedEntity(_entity, _entityId) {
        if (entityIdLocation[_entity][_entityId] != 0) {
            revert AlreadySpawned(_entity, _entityId);
        }
        if (_entity != ADMIN_CHARACTER) {
            _entity.spawnSet().revertIfNotInSet(_locationId);
        }
        _add(_entity, _entityId, _locationId);
        emit Move(_entity, _entityId, 0, _locationId);
    }

    //Despawns an entity at location, so it leaves the game.
    function despawn(
        IEntity _entity,
        uint256 _entityId
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        _del(_entity, _entityId, _curr);
        emit Move(_entity, _entityId, _curr, 0);
    }

    //Moves an entity to a new location.
    function move(
        IEntity _entity,
        uint256 _entityId,
        uint256 _dest
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        uint256 curr = entityIdLocation[_entity][_entityId];
        _tfr(_entity, _entityId, curr, _dest);
        emit Move(_entity, _entityId, curr, _dest);
    }

    function _add(
        IEntity _entity,
        uint256 _entityId,
        uint256 _dest
    ) internal onlyEntityIdSetExists(_dest, _entity) {
        if (address(locationEntityIdSet[_dest][_entity]) == address(0x0)) {
            locationEntityIdSet[_dest][
                _entity
            ] = new EnumerableSetAccessControlViewableUint256(this);
        }
        locationEntityIdSet[_dest][_entity].add(_entityId);
        entityIdLocation[_entity][_entityId] = _dest;
    }

    function _del(IEntity _entity, uint256 _entityId, uint256 _curr) internal {
        locationEntityIdSet[_curr][_entity].remove(_entityId);
        delete entityIdLocation[_entity][_entityId];
    }

    function _tfr(
        IEntity _entity,
        uint256 _entityId,
        uint256 _curr,
        uint256 _dest
    ) internal onlyEntityIdSetExists(_dest, _entity) {
        locationEntityIdSet[_curr][_entity].remove(_entityId);
        _add(_entity, _entityId, _dest);
    }
}
