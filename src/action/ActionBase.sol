// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IAction} from "../interfaces/IAction.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import {ActionRevertsLib} from "./ActionRevertsLib.sol";
import {AccessRoleManager} from "../roles/AccessRoleManager.sol";
import {AccessRoleAdmin} from "../roles/AccessRoleAdmin.sol";
import {DatastoreEntityLocation} from "../datastores/DatastoreEntityLocation.sol";
import {DatastoreEntityActionLock} from "../datastores/DatastoreEntityActionLock.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {HasRSBlacklist} from "../utils/HasRSBlacklist.sol";
import {RegionSettings} from "../RegionSettings.sol";

abstract contract ActionBase is IAction, HasRSBlacklist, AccessRoleAdmin {
    string public metadataIpfsCID;

    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 public constant DATASTORE_ENTITY_ACTION_LOCK =
        keccak256("DATASTORE_ENTITY_ACTION_LOCK");

    constructor(address _manager, RegionSettings _rs) HasRSBlacklist(_rs) {
        revertIfAccountBlacklisted(_manager);
        revertIfAccountBlacklisted(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, regionSettings.governance());
        _grantRole(MANAGER_ROLE, _manager);
    }
    function execute(
        address _locCaller,
        ILocation _location,
        IEntity _entity,
        uint256 _entityID,
        bytes calldata //_param
    ) public virtual {
        ActionRevertsLib.revertIfSenderNotLocation(_location);
        ActionRevertsLib.revertIfLocCallerNotEntityOwner(
            _locCaller,
            _entity,
            _entityID
        );
        ActionRevertsLib.revertIfEntityNotAtLocation(
            DatastoreEntityLocation(
                regionSettings.registries(DATASTORE_ENTITY_LOCATION)
            ),
            _location,
            _entity,
            _entityID
        );
        ActionRevertsLib.revertIfActionLocked(
            DatastoreEntityActionLock(
                regionSettings.registries(DATASTORE_ENTITY_ACTION_LOCK)
            ),
            this,
            _entity,
            _entityID
        );
    }
    function setMetadata(string calldata to) external onlyAdmin {
        metadataIpfsCID = to;
    }
}
