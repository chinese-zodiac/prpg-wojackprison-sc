// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IEntity} from "./interfaces/IEntity.sol";
import {IAction} from "./interfaces/IAction.sol";
import {ModifierBlacklisted} from "./utils/ModifierBlacklisted.sol";
import {AccessRoleAdmin} from "./roles/AccessRoleAdmin.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {GlobalSettings} from "./GlobalSettings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DatastoreLocationEntityPermissions} from "./datastores/DatastoreLocationEntityPermissions.sol";

contract Executor is
    ModifierBlacklisted,
    ReentrancyGuard,
    AccessRoleAdmin,
    AccessControlEnumerable
{
    bytes32 public constant DATASTORE_LOCATION_ENTITY_PERMISSIONS =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 public constant DATASTORE_LOCATION_ACTIONS =
        keccak256("DATASTORE_LOCATION_ACTIONS");
    GlobalSettings public globalSettings;
    event SetGlobalSettings(globalSettings globalSettings);

    event Execute(
        address sender,
        ILocation location,
        IEntity entity,
        uint256 entityID,
        bytes32 actionKey,
        IAction action
    );

    error InvalidAction(IAction ac);
    error FailedCall(address callee, bytes encodedCall);
    error InvalidExecuteReturn();

    constructor() {
        globalSettings = _globalSettings;
        emit SetGlobalSettings(globalSettings);
        _grantRole(DEFAULT_ADMIN_ROLE, globalSettings.governance());

        revertIfAccountBlacklisted(msg.sender);
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        bytes32 _actionKey,
        bytes calldata _param
    )
        external
        nonReentrant
        blacklisted(this, msg.sender)
        blacklistedEntity(this, _entity, _entityID)
    {
        DatastoreLocationEntityPermissions(
            globalSettings.registries[DATASTORE_LOCATION_ENTITY_PERMISSIONS]
        ).revertIfEntityLacksPermission();
        //TODO: Revert if action is not in entity location's DATASTORE_LOCATION_ACTIONS
        (address[] memory callees, bytes[] memory encodedCalls) = actions[
            _actionKey
        ].execute(msg.sender, this, _entity, _entityID, _param);
        if (callees.length != encodedCalls.length)
            revert InvalidExecuteReturn();
        for (uint256 i; i < callees.length; i++) {
            _actionCall(_callees[i], encodedCalls[i]);
        }
    }

    function _actionCall(
        address _callee,
        bytes calldata _encodedCall
    ) internal {
        //1. For security, DataStores require the sender to be the ExecuteAction
        //2. Actions need to store their own data, such as registry keys,
        // so ac.execute() cannot be delegatecall.
        //1 & 2 is why the AC encodes the call and passes it to the ExecuteAction.
        //This means for security Locations should ONLY add trusted Actions,
        //but it also means that a malicious Action can only steal from EntityIds that are at the hacked Location.
        //Actions should use `abi.encodeCall` for type checking to encode the call.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _callee.call(_encodedCall);
        if (!success) {
            revert FailedCall(_callee, _encodedCall);
        }
    }

    function revertIfAccountBlacklisted(address account) public view {
        globalSettings.tenXBlacklist().revertIfAccountBlacklisted(account);
    }

    function revertIfEntityOwnerBlacklisted(
        IEntity _entity,
        uint256 _entityID
    ) external view {
        revertIfAccountBlacklisted(_entity.ownerOf(_entityID));
    }

    function setglobalSettings(
        GlobalSettings _globalSettings
    ) external onlyAdmin {
        globalSettings = _globalSettings;
        emit SetglobalSettings(globalSettings);
    }
}
