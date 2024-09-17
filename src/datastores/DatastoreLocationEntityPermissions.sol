// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Authorizer} from "../Authorizer.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {HasRSBlacklist} from "../utils/HasRSBlacklist.sol";
import {DatastoreEntityLocation} from "./DatastoreEntityLocation.sol";
import {EnumerableSetAccessControlViewableUint256} from "../utils/EnumerableSetAccessControlViewableUint256.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import {IKey} from "../interfaces/IKey.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//Stores a Lock for an Action.
//Action calls Lock to set an Unlock Action key,
//Then when the Action that has the unlock action key  is called, it must call unlock.
contract DatastoreLocationEntityPermissions is
    ReentrancyGuard,
    HasRSBlacklist,
    Authorizer,
    IKey
{
    bytes32 public constant KEY =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 public constant PERMISSION_DEFAULT_ADMIN_ENTITY = bytes32(0x0);

    using SafeERC20 for IERC20;

    mapping(ILocation location => mapping(bytes32 permissionKey => EnumerableSetAccessControlViewableAddress entities))
        public locationPermissionedEntitiesSet;
    mapping(ILocation location => mapping(bytes32 permissionKey => mapping(IEntity => EnumerableSetAccessControlViewableUint256 entityIds)))
        public locationPermissionedEntityIdsSet;
    mapping(ILocation location => EnumerableSetAccessControlViewableBytes32 permissionKeys)
        public locationPermissionKeys;

    mapping(ILocation location => mapping(bytes32 permissionKey => bytes32 permissionManagerKey))
        public permissionManagerKeys;

    event AddPermissionedEntitySet(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey,
        EnumerableSetAccessControlViewableAddress entitySet
    );
    event AddPermissionedEntityIdSet(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey,
        EnumerableSetAccessControlViewableAddress entityIdSet
    );
    event DelPermissionedEntitySet(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey
    );
    event DelPermissionedEntityIdSet(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey
    );
    event AddPermissionEntity(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey
    );
    event AddPermissionEntityId(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey,
        uint256 permissionEntityId
    );
    event DelPermissionEntity(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey
    );
    event DelPermissionEntityId(
        ILocation location,
        IEntity entity,
        bytes32 permissionKey,
        uint256 permissionEntityId
    );
    event SetPermissionKeyPermissionManagerKey(
        ILocation location,
        bytes32 permissionKey,
        bytes32 permissionManagerKey
    );

    error EntityLacksPermission(
        ILocation _location,
        bytes32 _permissionKey,
        IEntity _entity,
        uint256 _entityId
    );

    modifier onlyEntityLocation(IEntity _entity, uint256 _entityId) {
        DatastoreEntityLocation(
            regionSettings.registries(DATASTORE_ENTITY_LOCATION)
        ).revertIfNotAccountIsEntityLocation(msg.sender, _entity, _entityId);
        _;
    }

    constructor(RegionSettings _rs) HasRSBlacklist(_rs) {
        _grantRole(DEFAULT_ADMIN_ROLE, _rs.governance());
        _grantRole(MANAGER_ROLE, address(this));
    }

    function revertIfEntityLacksPermission(
        ILocation _location,
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

    function revertIfEntityLacksPermissionManager(
        ILocation _location,
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
        bytes32 _permissionKey,
        bytes32 _permissionManagerKey
    ) external {
        permissionManagerKeys[ILocation(msg.sender)][
            _permissionKey
        ] = _permissionManagerKey;
        emit SetPermissionKeyPermissionManagerKey(
            ILocation(msg.sender),
            _permissionKey,
            _permissionManagerKey
        );
    }

    function grantPermissionToEntity(
        bytes32 _permissionKey,
        IEntity _entity
    ) public {
        ILocation location = ILocation(msg.sender);
        updateLocationPermissionKeySets(location, _permissionKey, _entity);
        EnumerableSetAccessControlViewableBytes32 lpkSet = locationPermissionKeys[
                location
            ];
        EnumerableSetAccessControlViewableAddress lpeSet = locationPermissionedEntitiesSet[
                location
            ][_permissionKey];
        if (!lpkSet.getContains(_permissionKey)) {
            lpkSet.add(_permissionKey);
        }
        if (!lpeSet.getContains(address(_entity))) {
            lpeSet.add(address(_entity));
        }
    }

    function grantPermissionToEntityIds(
        bytes32 _permissionKey,
        IEntity _entity,
        uint256[] calldata _entityIds
    ) external {
        grantPermissionToEntity(_permissionKey, _entity);
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                ILocation(msg.sender)
            ][_permissionKey][_entity];
        for (uint256 i; i < _entityIds.length; i++) {
            if (!lpeiSet.getContains(_entityIds[i])) lpeiSet.add(_entityIds[i]);
        }
    }

    function revokePermissionToEntity(
        bytes32 _permissionKey,
        IEntity _entity
    ) external {
        locationPermissionedEntitiesSet[ILocation(msg.sender)][_permissionKey]
            .remove(address(_entity));
    }

    function revokePermissionToEntityIds(
        bytes32 _permissionKey,
        IEntity _entity,
        uint256[] calldata _entityIds
    ) external {
        EnumerableSetAccessControlViewableUint256 lpeiSet = locationPermissionedEntityIdsSet[
                ILocation(msg.sender)
            ][_permissionKey][_entity];
        for (uint256 i; i < _entityIds.length; i++) {
            if (lpeiSet.getContains(_entityIds[i]))
                lpeiSet.remove(_entityIds[i]);
        }
    }

    function updateLocationPermissionKeySets(
        ILocation _location,
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
        if (address(lpkSet) == address(0x0))
            locationPermissionKeys[
                _location
            ] = new EnumerableSetAccessControlViewableBytes32(this);
        if (address(lpeSet) == address(0x0))
            locationPermissionedEntitiesSet[_location][
                _permissionKey
            ] = new EnumerableSetAccessControlViewableAddress(this);
        if (address(lpeiSet) == address(0x0))
            locationPermissionedEntityIdsSet[_location][_permissionKey][
                _entity
            ] = new EnumerableSetAccessControlViewableUint256(this);
    }
}
