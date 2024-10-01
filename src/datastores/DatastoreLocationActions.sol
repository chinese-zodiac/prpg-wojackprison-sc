// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {DatastoreBase} from "./DatastoreBase.sol";
import {RegistryAction} from "../registry/RegistryAction.sol";
import {RegistryDatastore} from "../registry/RegistryDatastore.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {EACSetBytes32} from "../utils/EACSetBytes32.sol";
import {DatastoreLocationEntityPermissions} from "./DatastoreLocationEntityPermissions.sol";

contract DatastoreLocationActions is DatastoreBase {
    bytes32 public constant KEY = keccak256("DATASTORE_LOCATION_ACTIONS");
    bytes32 public constant REGISTRY_ACTION = keccak256("REGISTRY_ACTION");
    bytes32 public constant REGISTRY_DATASTORE =
        keccak256("REGISTRY_DATASTORE");
    bytes32 public constant DATASTORE_LOCATION_ENTITY_PERMISSIONS =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 internal constant PERMISSION_SET_ACTION =
        bytes32("PERMISSION_SET_ACTION");

    event AddActionKeySet(uint256 locID, EACSetBytes32 keySet);

    error LocationDoesNotContainActionKey(uint256 locID, bytes32 actionKey);

    mapping(uint256 locationID => EACSetBytes32 keySet) actionKeySet;

    constructor(IExecutor _executor) DatastoreBase(_executor) {}

    function updateLocationActionKeySet(uint256 _locID) public {
        if (address(actionKeySet[_locID]) == address(0x0)) {
            actionKeySet[_locID] = new EACSetBytes32();
        }
        //TODO: Add default action keys
    }

    function revertIfActionNotAtLocation(
        uint256 _locID,
        bytes32 _actionKey
    ) external view {
        if (!actionKeySet[_locID].getContains(_actionKey)) {
            revert LocationDoesNotContainActionKey(_locID, _actionKey);
        }
    }

    function addActionKey(
        uint256 _locID,
        IEntity _setterEntity,
        uint256 _setterEntityId,
        bytes32 _actionKey
    ) external onlyExecutor(X) {
        updateLocationActionKeySet(_locID);
        DatastoreLocationEntityPermissions(
            address(
                RegistryDatastore(
                    X.globalSettings().registries(REGISTRY_DATASTORE)
                ).entries(DATASTORE_LOCATION_ENTITY_PERMISSIONS)
            )
        ).revertIfEntityLacksPermission(
                _locID,
                PERMISSION_SET_ACTION,
                _setterEntity,
                _setterEntityId
            );
        RegistryAction(X.globalSettings().registries(REGISTRY_ACTION))
            .revertIfKeyDoesNotExist(_actionKey);
        actionKeySet[_locID].add(_actionKey);
    }

    function removeActionKey(
        uint256 _locID,
        IEntity _setterEntity,
        uint256 _setterEntityId,
        bytes32 _actionKey
    ) external onlyExecutor(X) {
        DatastoreLocationEntityPermissions(
            address(
                RegistryDatastore(
                    X.globalSettings().registries(REGISTRY_DATASTORE)
                ).entries(DATASTORE_LOCATION_ENTITY_PERMISSIONS)
            )
        ).revertIfEntityLacksPermission(
                _locID,
                PERMISSION_SET_ACTION,
                _setterEntity,
                _setterEntityId
            );
        actionKeySet[_locID].remove(_actionKey);
    }
}
