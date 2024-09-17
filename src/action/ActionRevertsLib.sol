// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IAction} from "../interfaces/IAction.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {DatastoreEntityLocation} from "../datastores/DatastoreEntityLocation.sol";
import {DatastoreEntityActionLock} from "../datastores/DatastoreEntityActionLock.sol";
import "./ActionErrors.sol" as ActionErrors;

library ActionRevertsLib {
    function revertIfLocCallerNotEntityOwner(
        address _locCaller,
        IEntity _entity,
        uint256 _entityID
    ) internal view {
        if (_entity.ownerOf(_entityID) != _locCaller) {
            revert ActionErrors.LocCallerNotEntityOwner(
                _locCaller,
                _entity,
                _entityID
            );
        }
    }

    function revertIfSenderNotLocation(ILocation _location) internal view {
        if (msg.sender != address(_location)) {
            revert ActionErrors.SenderNotLocation(msg.sender, _location);
        }
    }

    function revertIfActionLocked(
        DatastoreEntityActionLock _datastoreEntityActionLock,
        IAction _action,
        IEntity _entity,
        uint256 _entityID
    ) internal view {
        if (
            _datastoreEntityActionLock.isLocked(
                _entity,
                _entityID,
                _action.KEY()
            )
        ) {
            revert ActionErrors.ActionLocked(_entity, _entityID, _action.KEY());
        }
    }

    function revertIfEntityNotAtLocation(
        DatastoreEntityLocation _datastoreEntityLocation,
        ILocation _location,
        IEntity _entity,
        uint256 _entityID
    ) internal view {
        _datastoreEntityLocation.revertIfNotAccountIsEntityLocation(
            address(_location),
            _entity,
            _entityID
        );
    }
}
