// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IExecutor} from "./interfaces/IExecutor.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {IAction} from "./interfaces/IAction.sol";
import {ModifierBlacklisted} from "./utils/ModifierBlacklisted.sol";
import {AccessRoleAdmin} from "./roles/AccessRoleAdmin.sol";
import {GlobalSettings} from "./GlobalSettings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {DatastoreLocationEntityPermissions} from "./datastores/DatastoreLocationEntityPermissions.sol";
import {DatastoreEntityLocation} from "./datastores/DatastoreEntityLocation.sol";
import {RegistryDatastore} from "./registry/RegistryDatastore.sol";
import {RegistryAction} from "./registry/RegistryAction.sol";

contract Executor is
    ModifierBlacklisted,
    ReentrancyGuard,
    AccessRoleAdmin,
    IExecutor
{
    bytes32 internal constant DATASTORE_LOCATION_ENTITY_PERMISSIONS =
        keccak256("DATASTORE_LOCATION_ENTITY_PERMISSIONS");
    bytes32 internal constant DATASTORE_LOCATION_ACTIONS =
        keccak256("DATASTORE_LOCATION_ACTIONS");
    bytes32 internal constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    bytes32 internal constant REGISTRY_DATASTORE =
        keccak256("REGISTRY_DATASTORE");
    bytes32 internal constant REGISTRY_ACTION = keccak256("REGISTRY_ACTION");
    GlobalSettings public globalSettings;
    event SetGlobalSettings(GlobalSettings globalSettings);

    event Execute(
        address sender,
        uint256 locId,
        IEntity entity,
        uint256 entityID,
        bytes32 actionKey,
        IAction action
    );

    error InvalidAction(IAction ac);
    error FailedCall(address callee, bytes encodedCall);
    error InvalidExecuteReturn();

    constructor(GlobalSettings _globalSettings) {
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
        RegistryDatastore rDS = RegistryDatastore(
            globalSettings.registries(REGISTRY_DATASTORE)
        );
        DatastoreLocationEntityPermissions(
            address(rDS.entries(DATASTORE_LOCATION_ENTITY_PERMISSIONS))
        ).revertIfEntityLacksPermission(
                DatastoreEntityLocation(
                    address(rDS.entries(DATASTORE_ENTITY_LOCATION))
                ).entityLocation(_entity, _entityID),
                _actionKey,
                _entity,
                _entityID
            );
        //TODO: Revert if action is not in entity location's DATASTORE_LOCATION_ACTIONS
        //TODO: Revert if action locked
        (address[] memory callees, bytes[] memory encodedCalls) = IAction(
            address(
                RegistryAction(globalSettings.registries(REGISTRY_ACTION))
                    .entries(_actionKey)
            )
        ).execute(msg.sender, _entity, _entityID, _param);
        if (callees.length != encodedCalls.length)
            revert InvalidExecuteReturn();
        for (uint256 i; i < callees.length; i++) {
            _actionCall(callees[i], encodedCalls[i]);
        }
    }

    function _actionCall(address _callee, bytes memory _encodedCall) internal {
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
        emit SetGlobalSettings(globalSettings);
    }
}
