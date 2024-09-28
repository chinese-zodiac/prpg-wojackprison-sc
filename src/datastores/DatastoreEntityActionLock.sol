// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {DatastoreEntityLocation} from "./DatastoreEntityLocation.sol";
import {DatastoreLocationActions} from "./DatastoreLocationActions.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DatastoreBase} from "./DatastoreBase.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {RegistryDatastore} from "../registry/RegistryDatastore.sol";
//Stores a Lock for an Action.
//Action calls Lock to set an Unlock Action key,
//Then when the Action that has the unlock action key  is called, it must call unlock.
contract DatastoreEntityActionLock is DatastoreBase {
    bytes32 public constant KEY = keccak256("DATASTORE_ENTITY_ACTION_LOCK");
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 internal constant DATASTORE_LOCATION_ACTIONS =
        keccak256("DATASTORE_LOCATION_ACTIONS");
    bytes32 internal constant REGISTRY_DATASTORE =
        keccak256("REGISTRY_DATASTORE");

    mapping(IERC721 entity => mapping(uint256 entityId => bytes32 unlockActionKey))
        public entityActionLock;

    event Lock(IEntity entity, uint256 entityId, bytes32 unlockActionKey);

    event Unlock(IEntity entity, uint256 entityId, bytes32 unlockActionKey);

    error AlreadyLocked(
        IEntity entity,
        uint256 entityId,
        bytes32 currentUnlockActionKey,
        bytes32 attemptedUnlockActionKey
    );
    error NotLocked(IEntity entity, uint256 entityId, bytes32 actionKey);
    error InvalidUnlockActionKey(bytes32 unlockActionKey);
    error WrongUnlockActionKey(
        IEntity entity,
        uint256 entityId,
        bytes32 currentUnlockActionKey,
        bytes32 attemptedUnlockActionKey
    );
    error IsLocked(IEntity entity, uint256 entityId, bytes32 actionKey);

    constructor(IExecutor _executor) DatastoreBase(_executor) {}

    function revertIfIsLocked(
        IEntity entity,
        uint256 entityId,
        bytes32 actionKey
    ) external view {
        if (isLocked(entity, entityId, actionKey)) {
            revert IsLocked(entity, entityId, actionKey);
        }
    }

    function isLocked(
        IEntity entity,
        uint256 entityId,
        bytes32 actionKey
    ) public view returns (bool) {
        if (entityActionLock[entity][entityId] == bytes32(0x0)) return false;
        if (entityActionLock[entity][entityId] == actionKey) return false;
        return true;
    }

    function lock(
        IEntity _entity,
        uint256 _entityId,
        bytes32 _unlockActionKey
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        if (entityActionLock[_entity][_entityId] != bytes32(0x0)) {
            revert AlreadyLocked(
                _entity,
                _entityId,
                entityActionLock[_entity][_entityId],
                _unlockActionKey
            );
        }
        RegistryDatastore rDS = RegistryDatastore(
            X.globalSettings().registries(REGISTRY_DATASTORE)
        );
        uint256 locID = DatastoreEntityLocation(
            address(rDS.entries(DATASTORE_ENTITY_LOCATION))
        ).entityLocation(_entity, _entityId);
        DatastoreLocationActions(
            address(rDS.entries(DATASTORE_LOCATION_ACTIONS))
        ).revertIfActionNotAtLocation(locID, _unlockActionKey);
        entityActionLock[_entity][_entityId] = _unlockActionKey;
        emit Lock(_entity, _entityId, _unlockActionKey);
    }

    function unlock(
        IEntity _entity,
        uint256 _entityId,
        bytes32 _unlockActionKey
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        if (entityActionLock[_entity][_entityId] != bytes32(0x0)) {
            revert NotLocked(_entity, _entityId, _unlockActionKey);
        }
        if (entityActionLock[_entity][_entityId] != _unlockActionKey) {
            revert WrongUnlockActionKey(
                _entity,
                _entityId,
                entityActionLock[_entity][_entityId],
                _unlockActionKey
            );
        }
        delete entityActionLock[_entity][_entityId];
        emit Unlock(_entity, _entityId, _unlockActionKey);
    }
}
