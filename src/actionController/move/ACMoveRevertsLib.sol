// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {ACMove} from "./../move/ACMove.sol";
import {IEntity} from "../../interfaces/IEntity.sol";
import {IActionController} from "../../interfaces/IActionController.sol";
import {ILocation} from "../../interfaces/ILocation.sol";
import {EnumerableSetAccessControlViewableAddress} from "../../utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../../utils/EnumerableSetAccessControlViewableBytes32.sol";
import "./ACMoveErrors.sol" as ACMoveErrors;
import {MovementPreparation} from "./ACMoveStructs.sol";
import {Timers} from "../../libs/Timers.sol";

library ACMoveRevertsLib {
    using Timers for Timers.Timestamp;
    function revertIfInvalidDestination(
        mapping(ILocation location => EnumerableSetAccessControlViewableAddress set)
            storage destinationSet,
        ILocation _source,
        ILocation _destination
    ) internal view {
        if (!destinationSet[_source].getContains(address(_destination))) {
            revert ACMoveErrors.InvalidDestination(_source, _destination);
        }
    }

    function revertIfTimedDestination(
        mapping(ILocation source => mapping(ILocation destination => uint64 travelTime))
            storage travelTime,
        ILocation _source,
        ILocation _destination
    ) internal view {
        if (travelTime[_source][_destination] > 0) {
            revert ACMoveErrors.TimedDestination(
                _source,
                _destination,
                travelTime[_source][_destination]
            );
        }
    }

    function revertIfNotTimedDestination(
        mapping(ILocation source => mapping(ILocation destination => uint64 travelTime))
            storage travelTime,
        ILocation _source,
        ILocation _destination
    ) internal view {
        if (travelTime[_source][_destination] == 0) {
            revert ACMoveErrors.OnlyTimedDestination(_source, _destination);
        }
    }

    function revertIfMovementPreperationNotReady(
        mapping(IEntity entity => mapping(uint256 entityID => MovementPreparation preparation))
            storage movePrepares,
        IEntity _entity,
        uint256 _entityID
    ) internal view {
        if (movePrepares[_entity][_entityID].readyTimer.isPending()) {
            revert ACMoveErrors.NotReadyToMove(
                _entity,
                _entityID,
                movePrepares[_entity][_entityID].readyTimer.getDeadline()
            );
        }
    }

    function revertIfEntityNotAtLocation(
        ACMove _actionController,
        ILocation _location,
        IEntity _entity,
        uint256 _entityID
    ) internal view {
        ILocation entityLocation = _actionController.entityIdLocation(
            _entity,
            _entityID
        );
        if (entityLocation != _location) {
            revert ACMoveErrors.EntityNotAtLocation(
                _entity,
                _entityID,
                _location,
                entityLocation
            );
        }
    }
}
