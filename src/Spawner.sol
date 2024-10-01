// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {ISpawner} from "./interfaces/ISpawner.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ModifierBlacklisted} from "./utils/ModifierBlacklisted.sol";
import {IExecutor} from "./interfaces/IExecutor.sol";
import {DatastoreLocationEntityPermissions} from "./datastores/DatastoreLocationEntityPermissions.sol";
import {DatastoreEntityLocation} from "./datastores/DatastoreEntityLocation.sol";
import {RegistryDatastore} from "./registry/RegistryDatastore.sol";

contract Spawner is ModifierBlacklisted, ReentrancyGuard, ISpawner {
    bytes32 internal constant DATASTORE_LOCATION_ENTITY_PERMISSIONS =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 internal constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 internal constant REGISTRY_DATASTORE =
        keccak256("REGISTRY_DATASTORE");
    bytes32 internal constant PERMISSION_SPAWN = keccak256("PERMISSION_SPAWN");

    IExecutor internal immutable X;
    IEntity internal immutable ADMIN;

    error OnlyAdminCharCanSpawnAtLoc0();

    constructor(IExecutor _executor, IEntity _adminCharacter) {
        X = _executor;
        ADMIN = _adminCharacter;
    }

    function spawn(
        uint256 _locationID, //For spawning admin, use _locationID == 0
        IEntity _entity,
        address _receiver
    )
        external
        nonReentrant
        blacklisted(X, msg.sender)
        blacklisted(X, _receiver)
    {
        if (_locationID == 0 && _entity != ADMIN) {
            revert OnlyAdminCharCanSpawnAtLoc0();
        }
        uint256 spawnLoc = _locationID;
        RegistryDatastore rDS = RegistryDatastore(
            X.globalSettings().registries(REGISTRY_DATASTORE)
        );

        DatastoreLocationEntityPermissions dsLEP = DatastoreLocationEntityPermissions(
                address(rDS.entries(DATASTORE_LOCATION_ENTITY_PERMISSIONS))
            );

        uint256 entityID = _entity.mint(_receiver);

        //Grant admin permissions
        if (_entity == ADMIN) {
            dsLEP.grantAdminCharPermissions(_entity, entityID);
            //Admins are always spawned at a new location equal to their ID
            spawnLoc = entityID;
            //TODO: Add location to registry
        } else {
            // check permissions for non-admins
            dsLEP.revertIfEntityAllLacksPermission(
                _locationID,
                PERMISSION_SPAWN,
                _entity
            );
        }

        //Spawn to location
        DatastoreEntityLocation(address(rDS.entries(DATASTORE_ENTITY_LOCATION)))
            .spawn(_entity, entityID, spawnLoc);

        if (_entity != ADMIN) {}
    }
}
