// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./LocationBase.sol";
import "./LocWithTokenStore.sol";
import "./PlayerWithStats.sol";
import "./libs/Timers.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract LocPrepareMove is
    LocationBase,
    PlayerWithStats,
    LocWithTokenStore
{
    using Timers for Timers.Timestamp;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    mapping(ILocation location => bool isTimed) public isDestinationTimed;

    struct MovementPreparation {
        Timers.Timestamp readyTimer;
        ILocation destination;
    }
    mapping(uint256 => MovementPreparation) movePreps;

    //travelTime is consumed by a booster
    uint64 public travelTime = 4 hours;
    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME"));

    constructor() {}

    function prepareMoveTimed(
        uint256 playerID,
        ILocation destination
    ) external onlyLocalEntity(player, playerID) onlyPlayerOwner(playerID) {
        require(isDestinationTimed[destination]);
        movePreps[playerID].destination = destination;
        movePreps[playerID].readyTimer.setDeadline(
            uint64(
                block.timestamp +
                    playerStat(playerID, BOOSTER_PLAYER_TRAVELTIME)
            )
        );
        _onPrepareMove(playerID);
    }

    function _onPrepareMove(uint256 playerID) internal virtual {}

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual override(ILocation, LocationBase) {
        if (isDestinationTimed[_to] && _entity == player) {
            //timed destination checks
            require(
                movePreps[_entityID].readyTimer.isExpired(),
                "Player not ready to move"
            );
            require(
                _to == movePreps[_entityID].destination,
                "Player not prepared to travel there"
            );
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
    ) public onlyRole(VALID_ROUTE_SETTER) {
        setValidDestionation(_destinations, isTimed);
        for (uint i; i < _destinations.length; i++) {
            isDestinationTimed[_destinations[i]] = isTimed;
        }
    }

    function setTravelTime(uint64 to) external onlyRole(MANAGER_ROLE) {
        travelTime = to;
    }
}
