// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {ILocation} from "./interfaces/ILocation.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {IKey} from "./interfaces/IKey.sol";
import {IAction} from "./interfaces/IAction.sol";
import {IAuthorizer} from "./interfaces/IAuthorizer.sol";
import {Authorizer} from "./Authorizer.sol";
import {RegionSettings} from "./RegionSettings.sol";
import {EnumerableSetAccessControlViewableBytes32} from "./utils/EnumerableSetAccessControlViewableBytes32.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {HasRSBlacklist} from "./utils/HasRSBlacklist.sol";

contract Location is ReentrancyGuard, HasRSBlacklist, Authorizer, ILocation {
    bytes32 public immutable SETTER_ROLE = bytes32("SETTER_ROLE");
    EnumerableSetAccessControlViewableBytes32 public actionSet;
    mapping(bytes32 actionKey => IAction action) public actions;

    event ExecuteAction(
        address sender,
        ILocation location,
        IEntity entity,
        uint256 entityID,
        bytes32 actionKey,
        IAction action
    );
    event SetActionSet(EnumerableSetAccessControlViewableBytes32 actionSet);

    error InvalidAction(IAction ac);
    error FailedDatastoreCommit(address datastore, bytes data);

    modifier onlySetter() {
        revertIfNotAuthorized(SETTER_ROLE, msg.sender);
        _;
    }
    constructor(address _setter, RegionSettings _rs) HasRSBlacklist(_rs) {
        revertIfAccountBlacklisted(_setter);
        revertIfAccountBlacklisted(msg.sender);
        actionSet = new EnumerableSetAccessControlViewableBytes32(
            IAuthorizer(this)
        );
        emit SetActionSet(actionSet);

        _grantRole(DEFAULT_ADMIN_ROLE, regionSettings.governance());
        _grantRole(SETTER_ROLE, _setter);
        _grantRole(MANAGER_ROLE, address(this));
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        bytes32 _actionKey,
        bytes calldata _param
    ) external nonReentrant blacklisted blacklistedEntity(_entity, _entityID) {
        actionSet.revertIfNotInSet(_actionKey);
        actions[_actionKey].execute(
            msg.sender,
            this,
            _entity,
            _entityID,
            _param
        );
    }

    function commitToDatastore(address _ds, bytes calldata _data) external {
        bytes32 actionKey = IKey(msg.sender).KEY();
        actionSet.revertIfNotInSet(actionKey);
        if (actions[actionKey] != IAction(msg.sender)) {
            revert InvalidAction(IAction(msg.sender));
        }
        //1. For security, most DataStores require the sender to be the Entity's current location.
        //2. Actions need to store their own data, such as registry keys,
        // so ac.execute() cannot be delegatecall.
        //1 & 2 is why the AC encodes the call and passes it to the Location.
        //This means for security Locations should ONLY add trusted Actions,
        //but it also means that a malicious Action can only steal from EntityIds that are at the hacked Location.
        //Actions should use `abi.encodeCall` for type checking to encode the call.
        (bool success, ) = _ds.call(_data);
        if (!success) {
            revert FailedDatastoreCommit(_ds, _data);
        }
    }

    function addAction(IAction _action) external onlySetter {
        actionSet.add(_action.KEY());
        _action.start();
    }

    function deleteAction(IAction _action) external onlySetter {
        actionSet.remove(_action.KEY());
        _action.stop();
    }
}
