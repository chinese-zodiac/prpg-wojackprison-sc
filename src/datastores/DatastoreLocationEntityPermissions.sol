// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Authorizer} from "../Authorizer.sol";
import {Executor} from "../Executor.sol";
import {DatastoreEntityLocation} from "./DatastoreEntityLocation.sol";
import {EnumerableSetAccessControlViewableUint256} from "../utils/EnumerableSetAccessControlViewableUint256.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import {IKey} from "../interfaces/IKey.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AdminCharacter} from "../AdminCharacter.sol";
import {ModifierOnlyExecutor} from "../utils/ModifierOnlyExecutor.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {Executor} from "../Executor.sol";

//Stores a Lock for an Action.
//Action calls Lock to set an Unlock Action key,
//Then when the Action that has the unlock action key  is called, it must call unlock.
contract DatastoreLocationEntityPermissions is
    ReentrancyGuard,
    ModifierBlacklisted,
    ModifierOnlyExecutor,
    Authorizer,
    IKey
{
    bytes32 public constant KEY =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 internal constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 internal constant PERMISSION_DEFAULT_ADMIN_ENTITY = bytes32(0x0);

    Executor internal immutable X;
    IEntity internal immutable ADMIN_CHARACTER;

    error OnlyAdminCharacter(address sender);

    using SafeERC20 for IERC20;

    mapping(uint256 locID => mapping(bytes32 permissionKey => EnumerableSetAccessControlViewableAddress entities))
        public locationPermissionedEntitiesSet;
    mapping(uint256 locID => mapping(bytes32 permissionKey => mapping(IEntity => EnumerableSetAccessControlViewableUint256 entityIds)))
        public locationPermissionedEntityIdsSet;
    mapping(uint256 locID => EnumerableSetAccessControlViewableBytes32 permissionKeys)
        public locationPermissionKeys;

    mapping(uint256 locID => mapping(bytes32 permissionKey => bytes32 permissionManagerKey))
        public permissionManagerKeys;

    event AddPermissionedEntitySet(
        uint256 locID,
        bytes32 permissionKey,
        EnumerableSetAccessControlViewableAddress entitySet
    );
    event AddPermissionedKeysSet(
        uint256 locID,
        EnumerableSetAccessControlViewableBytes32 keySet
    );
    event AddPermissionedEntityIdSet(
        uint256 locID,
        IEntity entity,
        bytes32 permissionKey,
        EnumerableSetAccessControlViewableUint256 entityIdSet
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

    constructor(Executor _executor, AdminCharacter _admin) {
        X = _executor;
        ADMIN_CHARACTER = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, _rs.governance());
        _grantRole(MANAGER_ROLE, address(this));

        //TODO: Spawn admin 0
        //Admin entity 0 administrates location 0
        //location 0 is used to spawn administrators for new locations
        // with ACTION_SPAWN_ADMIN
    }

    //Special logic for admins to bootstrap permissioning
    function grantAdminCharPermissions(uint256 adminID) public {
        if (msg.sender != address(ADMIN_CHARACTER)) {
            revert OnlyAdminCharacter(msg.sender);
        }
        //adminID and locationID are the same
        uint256 locID = adminID;
        updateLocationPermissionKeySets(
            locID,
            PERMISSION_DEFAULT_ADMIN_ENTITY,
            ADMIN_CHARACTER
        );
        locationPermissionKeys[_location].add(_permissionKey);
        locationPermissionedEntitiesSet[locID][_permissionKey].add(
            address(ADMIN_CHARACTER)
        );
        locationPermissionedEntityIdsSet[locID][_permissionKey][_entity].add(
            adminID
        );
    }

    function revertIfEntityAllLacksPermission(
        uint256 _locID,
        bytes32 _permissionKey,
        IEntity _entity
    ) public view {
        EnumerableSetAccessControlViewableBytes32 lpkSet = locationPermissionKeys[
                _location
            ];
        EnumerableSetAccessControlViewableAddress lpeSet = locationPermissionedEntitiesSet[
                _location
            ][_permissionKey];
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                _location
            ][_permissionKey][_entity];
        if (
            address(lpkSet) == address(0x0) ||
            !lpkSet.getContains(_permissionKey) ||
            !lpeSet.getContains(address(_entity)) ||
            lpeiSet.getLength() > 0
        ) {
            revert EntityLacksPermission(
                _location,
                _permissionKey,
                _entity,
                _entityId
            );
        }
    }

    function revertIfEntityLacksPermission(
        uint256 _locID,
        bytes32 _permissionKey,
        IEntity _entity,
        uint256 _entityId
    ) public view {
        EnumerableSetAccessControlViewableBytes32 lpkSet = locationPermissionKeys[
                _location
            ];
        EnumerableSetAccessControlViewableAddress lpeSet = locationPermissionedEntitiesSet[
                _location
            ][_permissionKey];
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                _location
            ][_permissionKey][_entity];
        if (
            address(lpkSet) == address(0x0) ||
            !lpkSet.getContains(_permissionKey) ||
            !lpeSet.getContains(address(_entity)) ||
            (lpeiSet.getLength() > 0 && !lpeiSet.getContains(_entityId))
        ) {
            revert EntityLacksPermission(
                _location,
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
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        updateLocationPermissionKeySets(_location, _permissionKey, _entity);
        EnumerableSetAccessControlViewableBytes32 lpkSet = locationPermissionKeys[
                _location
            ];
        EnumerableSetAccessControlViewableAddress lpeSet = locationPermissionedEntitiesSet[
                _location
            ][_permissionKey];
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
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        grantPermissionToEntity(_permissionKey, _entity);
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                _location
            ][_permissionKey][_entity];
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
        revertIfEntityLacksPermissionManager(
            _location,
            _permissionKey,
            _managerEntity,
            _managerEntityId
        );
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                _location
            ][_permissionKey][_entity];
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
        EnumerableSetAccessControlViewableBytes32 lpkSet = locationPermissionKeys[
                _location
            ];
        EnumerableSetAccessControlViewableAddress lpeSet = locationPermissionedEntitiesSet[
                _location
            ][_permissionKey];
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                _location
            ][_permissionKey][_entity];
        if (address(lpkSet) == address(0x0)) {
            locationPermissionKeys[
                _location
            ] = new EnumerableSetAccessControlViewableBytes32(this);
            emit AddPermissionedKeysSet(
                _location,
                locationPermissionKeys[_location]
            );
        }
        if (address(lpeSet) == address(0x0)) {
            locationPermissionedEntitiesSet[_location][
                _permissionKey
            ] = new EnumerableSetAccessControlViewableAddress(this);
            emit AddPermissionedEntitySet(
                _location,
                _permissionKey,
                locationPermissionedEntitiesSet[_location][_permissionKey]
            );
        }
        if (address(lpeiSet) == address(0x0)) {
            locationPermissionedEntityIdsSet[_location][_permissionKey][
                _entity
            ] = new EnumerableSetAccessControlViewableUint256(this);
            emit AddPermissionedEntityIdSet(
                _location,
                _entity,
                _permissionKey,
                locationPermissionedEntityIdsSet[_location][_permissionKey][
                    _entity
                ]
            );
        }
    }
}
