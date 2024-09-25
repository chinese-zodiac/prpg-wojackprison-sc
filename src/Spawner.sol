// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IEntity} from "./interfaces/IEntity.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ModifierBlacklisted} from "./utils/ModifierBlacklisted.sol";
import {Executor} from "./Executor.sol";
import {DatastoreLocationEntityPermissions} from "./datastores/DatastoreLocationEntityPermissions.sol";
import {DatastoreEntityLocation} from "./datastores/DatastoreEntityLocation.sol";

contract Spawner is ReentrancyGuard, ModifierBlacklisted {
    bytes32 internal constant DATASTORE_LOCATION_ENTITY_PERMISSIONS =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 internal constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 internal constant PERMISSION_SPAWN = keccak256("PERMISSION_SPAWN");

    Executor internal immutable X;

    constructor(Executor _executor) {
        X = _executor;
    }

    function spawn(
        uint256 _locationID,
        IEntity _entity,
        address _receiver
    )
        external
        nonReentrant
        blacklisted(X, msg.sender)
        blacklisted(X, _receiver)
    {
        // check permissions
        DatastoreLocationEntityPermissions(
            X.globalSettings().registries(DATASTORE_LOCATION_ENTITY_PERMISSIONS)
        ).revertIfEntityAllLacksPermission(
                _locationID,
                PERMISSION_SPAWN,
                _entity
            );
        // spawn
        DatastoreLocationEntityPermissions(
            X.globalSettings().registries(DATASTORE_LOCATION_ENTITY_PERMISSIONS)
        ).spawn(_entity, _entity.mint(_receiver), _locationID);
    }
}
