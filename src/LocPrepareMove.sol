// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {LocationBase} from "./LocationBase.sol";
import {LocWithTokenStore} from "./LocWithTokenStore.sol";
import {LocPlayerWithStats} from "./LocPlayerWithStats.sol";
import {Timers} from "./libs/Timers.sol";

abstract contract LocPrepareMove is
    LocationBase,
    LocPlayerWithStats,
    LocWithTokenStore
{
    using Timers for Timers.Timestamp;

    mapping(ILocation location => bool isTimed) public isDestinationTimed;

    struct MovementPreparation {
        Timers.Timestamp readyTimer;
        ILocation destination;
    }
    mapping(uint256 playerID => MovementPreparation preparation)
        internal movePreps;

    //travelTime is consumed by a booster
    uint64 public travelTime;
    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME_ADD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME_ADD"));
    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME_MUL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME_MUL"));

    event SetTravelTime(uint256 travelTime);
    event SetIsDestinationTimed(ILocation location, bool isTimed);
    event PrepareMoveTimed(
        uint256 playerID,
        ILocation destination,
        uint64 deadline
    );

    error OnlyTimedDestination(ILocation destination);
    error NotReadyToMove(
        IEntity entity,
        uint256 entityID,
        ILocation destination
    );
    error WrongTimedDestination(
        IEntity entity,
        uint256 entityID,
        ILocation destination
    );

    constructor(uint64 _travelTime) {
        travelTime = _travelTime;
        emit SetTravelTime(travelTime);
    }

    modifier onlyTimedDestination(ILocation destination) {
        if (!isDestinationTimed[destination]) {
            revert OnlyTimedDestination(destination);
        }
        _;
    }

    function prepareMoveTimed(
        uint256 playerID,
        ILocation destination
    )
        external
        onlyLocalEntity(PLAYER, playerID)
        onlyPlayerOwner(playerID)
        onlyTimedDestination(destination)
    {
        movePreps[playerID].destination = destination;
        uint64 deadline = uint64(
            block.timestamp +
                playerStat(
                    playerID,
                    BOOSTER_PLAYER_TRAVELTIME_ADD,
                    BOOSTER_PLAYER_TRAVELTIME_MUL
                )
        );
        movePreps[playerID].readyTimer.setDeadline(deadline);
        _onPrepareMove(playerID);
        emit PrepareMoveTimed(playerID, destination, deadline);
    }

    function _onPrepareMove(uint256 playerID) internal virtual;

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual override(ILocation, LocationBase) {
        if (isDestinationTimed[_to] && _entity == PLAYER) {
            //timed destination checks
            if (!movePreps[_entityID].readyTimer.isExpired()) {
                revert NotReadyToMove(_entity, _entityID, _to);
            }
            if (_to != movePreps[_entityID].destination) {
                revert WrongTimedDestination(_entity, _entityID, _to);
            }
            //reset timer
            movePreps[_entityID].readyTimer.reset();
        }
    }

    function playerDestination(
        uint256 playerID
    ) public view returns (ILocation) {
        return movePreps[playerID].destination;
    }

    function isPlayerPreparingToMove(
        uint256 playerID
    ) public view returns (bool) {
        return
            movePreps[playerID].readyTimer.isPending() ||
            isPlayerReadyToMove(playerID);
    }

    function isPlayerReadyToMove(uint256 playerID) public view returns (bool) {
        return movePreps[playerID].readyTimer.isExpired();
    }

    function whenPlayerIsReadyToMove(
        uint256 playerID
    ) public view returns (uint64) {
        return movePreps[playerID].readyTimer.getDeadline();
    }

    function setTimedDestination(
        ILocation[] calldata _destinations,
        bool isTimed
    ) public {
        if (
            !validDestinationSet.hasRole(
                validDestinationSet.MANAGER_ROLE(),
                msg.sender
            )
        ) {
            revert AccessControlUnauthorizedAccount(
                msg.sender,
                validDestinationSet.MANAGER_ROLE()
            );
        }
        for (uint256 i; i < _destinations.length; i++) {
            if (
                isTimed &&
                !validDestinationSet.getContains(address(_destinations[i]))
            ) {
                validDestinationSet.add(address(_destinations[i]));
            }
            isDestinationTimed[_destinations[i]] = isTimed;
        }
    }

    function setTravelTime(uint64 to) external onlyRole(MANAGER_ROLE) {
        travelTime = to;
    }
}
