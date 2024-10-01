// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {Executor} from "../Executor.sol";
import {DatastoreEntityLocation} from "./DatastoreEntityLocation.sol";
import {EACSetUint256} from "../utils/EACSetUint256.sol";
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {EACSetBytes32} from "../utils/EACSetBytes32.sol";
import {ModifierOnlySpawner} from "../utils/ModifierOnlySpawner.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {ISpawner} from "../interfaces/ISpawner.sol";
import {DatastoreBase} from "./DatastoreBase.sol";
//Stores a Lock for an Action.
//Action calls Lock to set an Unlock Action key,
//Then when the Action that has the unlock action key  is called, it must call unlock.
contract DatastoreLocationEntityPermissions is
    DatastoreBase,
    ModifierOnlySpawner
{
    bytes32 public constant KEY =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 internal constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 internal constant PERMISSION_DEFAULT_ADMIN_ENTITY = bytes32(0x0);
    bytes32 internal constant PERMISSION_SET_ACTION =
        bytes32("PERMISSION_SET_ACTION");

    ISpawner internal immutable S;

    mapping(uint256 locID => mapping(bytes32 permissionKey => EACSetAddress entities))
        public locationPermissionedEntitiesSet;
    mapping(uint256 locID => mapping(bytes32 permissionKey => mapping(IEntity => EACSetUint256 entityIds)))
        public locationPermissionedEntityIdsSet;
    mapping(uint256 locID => EACSetBytes32 permissionKeys)
        public locationPermissionKeys;

    mapping(uint256 locID => mapping(bytes32 permissionKey => bytes32 permissionManagerKey))
        public permissionManagerKeys;

    event AddPermissionedEntitySet(
        uint256 locID,
        bytes32 permissionKey,
        EACSetAddress entitySet
    );
    event AddPermissionedKeysSet(uint256 locID, EACSetBytes32 keySet);
    event AddPermissionedEntityIdSet(
        uint256 locID,
        IEntity entity,
        bytes32 permissionKey,
        EACSetUint256 entityIdSet
    );
    event SetPermissionKeyPermissionManagerKey(
        uint256 locID,
        bytes32 permissionKey,
        bytes32 permissionManagerKey
    );
    error EntityLacksPermission(
        uint256 locID,
        bytes32 _permissionKey,
        IEntity _entity,
        uint256 _entityId
    );

    constructor(
        IExecutor _executor,
        ISpawner _spawner
    ) DatastoreBase(_executor) {
        S = _spawner;
    }

    //Special logic for admins to bootstrap permissioning
    function grantAdminCharPermissions(
        IEntity _entity,
        uint256 _entityID
    ) public onlySpawner(S) {
        //adminID and locationID are the same

        uint256 locID = _entityID;
        //manage permissions
        updateLocationPermissionKeySets(
            locID,
            PERMISSION_DEFAULT_ADMIN_ENTITY,
            _entity
        );
        locationPermissionKeys[locID].add(PERMISSION_DEFAULT_ADMIN_ENTITY);
        locationPermissionedEntitiesSet[locID][PERMISSION_DEFAULT_ADMIN_ENTITY]
            .add(address(_entity));
        locationPermissionedEntityIdsSet[locID][
            PERMISSION_DEFAULT_ADMIN_ENTITY
        ][_entity].add(_entityID);
        //manage actions
        updateLocationPermissionKeySets(locID, PERMISSION_SET_ACTION, _entity);
        locationPermissionKeys[locID].add(PERMISSION_SET_ACTION);
        locationPermissionedEntitiesSet[locID][PERMISSION_SET_ACTION].add(
            address(_entity)
        );
        locationPermissionedEntityIdsSet[locID][PERMISSION_SET_ACTION][_entity]
            .add(_entityID);
    }

    function revertIfEntityAllLacksPermission(
        uint256 _locID,
        bytes32 _permissionKey,
        IEntity _entity
    ) public view {
        EACSetBytes32 lpkSet = locationPermissionKeys[_locID];
        EACSetAddress lpeSet = locationPermissionedEntitiesSet[_locID][
            _permissionKey
        ];
        EACSetUint256 lpeiSet = locationPermissionedEntityIdsSet[_locID][
            _permissionKey
        ][_entity];
        if (
            address(lpkSet) == address(0x0) ||
            !lpkSet.getContains(_permissionKey) ||
            !lpeSet.getContains(address(_entity)) ||
            lpeiSet.getLength() > 0
        ) {
            revert EntityLacksPermission(_locID, _permissionKey, _entity, 0);
        }
    }

    function revertIfEntityLacksPermission(
        uint256 _locID,
        bytes32 _permissionKey,
        IEntity _entity,
        uint256 _entityId
    ) public view {
        EACSetBytes32 lpkSet = locationPermissionKeys[_locID];
        EACSetAddress lpeSet = locationPermissionedEntitiesSet[_locID][
            _permissionKey
        ];
        EACSetUint256 lpeiSet = locationPermissionedEntityIdsSet[_locID][
            _permissionKey
        ][_entity];
        if (
            address(lpkSet) == address(0x0) ||
            !lpkSet.getContains(_permissionKey) ||
            !lpeSet.getContains(address(_entity)) ||
            (lpeiSet.getLength() > 0 && !lpeiSet.getContains(_entityId))
        ) {
            revert EntityLacksPermission(
                _locID,
                _permissionKey,
                _entity,
                _entityId
            );
        }
    }

    function revertIfEntityNotAdmin(
        uint256 _location,
        IEntity _adminEntity,
        uint256 _adminEntityId
    ) public view {
        revertIfEntityLacksPermission(
            _location,
            PERMISSION_DEFAULT_ADMIN_ENTITY,
            _adminEntity,
            _adminEntityId
        );
    }

    function revertIfEntityLacksPermissionManager(
        uint256 _location,
        bytes32 _permissionKey,
        IEntity _managerEntity,
        uint256 _managerEntityId
    ) public view {
        revertIfEntityLacksPermission(
            _location,
            permissionManagerKeys[_location][_permissionKey],
            _managerEntity,
            _managerEntityId
        );
    }

    //By default, permission manager key is bytes32(0x0)
    function setPermissionKeyPermissionManagerKey(
        uint256 _location,
        IEntity _managerEntity,
        uint256 _managerEntityId,
        bytes32 _permissionKey,
        bytes32 _permissionManagerKey
    ) external onlyExecutor(X) {
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        permissionManagerKeys[_location][
            _permissionKey
        ] = _permissionManagerKey;
        emit SetPermissionKeyPermissionManagerKey(
            _location,
            _permissionKey,
            _permissionManagerKey
        );
    }

    function grantPermissionToEntity(
        uint256 _location,
        IEntity _managerEntity,
        uint256 _managerEntityId,
        bytes32 _permissionKey,
        IEntity _entity
    ) public onlyExecutor(X) {
        //TODO: Fix location to be fetched from managerEntity
        updateLocationPermissionKeySets(_location, _permissionKey, _entity);
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        EACSetBytes32 lpkSet = locationPermissionKeys[_location];
        EACSetAddress lpeSet = locationPermissionedEntitiesSet[_location][
            _permissionKey
        ];
        if (!lpkSet.getContains(_permissionKey)) {
            lpkSet.add(_permissionKey);
        }
        if (!lpeSet.getContains(address(_entity))) {
            lpeSet.add(address(_entity));
        }
    }

    function grantPermissionToEntityIds(
        uint256 _location,
        IEntity _managerEntity,
        uint256 _managerEntityId,
        bytes32 _permissionKey,
        IEntity _entity,
        uint256[] memory _entityIds
    ) public onlyExecutor(X) {
        //TODO: Fix location to be fetched from managerEntity
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        grantPermissionToEntity(
            _location,
            _managerEntity,
            _managerEntityId,
            _permissionKey,
            _entity
        );
        EACSetUint256 lpeiSet = locationPermissionedEntityIdsSet[_location][
            _permissionKey
        ][_entity];
        for (uint256 i; i < _entityIds.length; i++) {
            if (!lpeiSet.getContains(_entityIds[i])) lpeiSet.add(_entityIds[i]);
        }
    }

    function revokePermissionToEntity(
        uint256 _location,
        IEntity _managerEntity,
        uint256 _managerEntityId,
        bytes32 _permissionKey,
        IEntity _entity
    ) external onlyExecutor(X) {
        //TODO: Fix location to be fetched from managerEntity
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        locationPermissionedEntitiesSet[_location][_permissionKey].remove(
            address(_entity)
        );
    }

    function revokePermissionToEntityIds(
        uint256 _location,
        IEntity _managerEntity,
        uint256 _managerEntityId,
        bytes32 _permissionKey,
        IEntity _entity,
        uint256[] calldata _entityIds
    ) external onlyExecutor(X) {
        //TODO: Fix location to be fetched from managerEntity
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        EACSetUint256 lpeiSet = locationPermissionedEntityIdsSet[_location][
            _permissionKey
        ][_entity];
        for (uint256 i; i < _entityIds.length; i++) {
            if (lpeiSet.getContains(_entityIds[i]))
                lpeiSet.remove(_entityIds[i]);
        }
    }

    function updateLocationPermissionKeySets(
        uint256 _location,
        bytes32 _permissionKey,
        IEntity _entity
    ) public {
        EACSetBytes32 lpkSet = locationPermissionKeys[_location];
        EACSetAddress lpeSet = locationPermissionedEntitiesSet[_location][
            _permissionKey
        ];
        EACSetUint256 lpeiSet = locationPermissionedEntityIdsSet[_location][
            _permissionKey
        ][_entity];
        if (address(lpkSet) == address(0x0)) {
            locationPermissionKeys[_location] = new EACSetBytes32();
            emit AddPermissionedKeysSet(
                _location,
                locationPermissionKeys[_location]
            );
        }
        if (address(lpeSet) == address(0x0)) {
            locationPermissionedEntitiesSet[_location][
                _permissionKey
            ] = new EACSetAddress();
            emit AddPermissionedEntitySet(
                _location,
                _permissionKey,
                locationPermissionedEntitiesSet[_location][_permissionKey]
            );
        }
        if (address(lpeiSet) == address(0x0)) {
            locationPermissionedEntityIdsSet[_location][_permissionKey][
                _entity
            ] = new EACSetUint256();
            emit AddPermissionedEntityIdSet(
                _location,
                _entity,
                _permissionKey,
                locationPermissionedEntityIdsSet[_location][_permissionKey][
                    _entity
                ]
            );
        }
        //TODO:Add default permission keys
    }
}
