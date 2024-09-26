// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IAction} from "../interfaces/IAction.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {EACSetBytes32} from "../utils/EACSetBytes32.sol";
import {ActionRevertsLib} from "./ActionRevertsLib.sol";
import {AccessRoleManager} from "../roles/AccessRoleManager.sol";
import {AccessRoleAdmin} from "../roles/AccessRoleAdmin.sol";
import {DatastoreEntityLocation} from "../datastores/DatastoreEntityLocation.sol";
import {DatastoreEntityActionLock} from "../datastores/DatastoreEntityActionLock.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Executor} from "../Executor.sol";
import {ModifierOnlyExecutor} from "../utils/ModifierOnlyExecutor.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";

abstract contract ActionBase is
    IAction,
    ModifierBlacklisted,
    ModifierOnlyExecutor,
    AccessRoleManager,
    AccessRoleAdmin
{
    string public metadataIpfsCID;
    Executor internal immutable X;

    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 public constant DATASTORE_ENTITY_ACTION_LOCK =
        keccak256("DATASTORE_ENTITY_ACTION_LOCK");

    constructor(address _manager, Executor _executor) {
        X = _executor;
        _grantRole(DEFAULT_ADMIN_ROLE, X.globalSettings().governance());
        _grantRole(MANAGER_ROLE, _manager);
    }
    function execute(
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes calldata //_param
    )
        public
        virtual
        onlyExecutor(X)
        returns (address[] memory callees_, bytes[] memory encodedCalls_)
    {}
    function setMetadata(string calldata to) external onlyAdmin {
        metadataIpfsCID = to;
    }
}
