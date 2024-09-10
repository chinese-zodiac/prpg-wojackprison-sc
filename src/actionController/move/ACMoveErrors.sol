// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../../interfaces/IEntity.sol";
import {ILocation} from "../../interfaces/ILocation.sol";

error InvalidDestination(ILocation source, ILocation destination);
error TimedDestination(
    ILocation source,
    ILocation destination,
    uint64 travelTime
);
error OnlyTimedDestination(ILocation source, ILocation destination);
error WrongTimedDestination(
    IEntity entity,
    uint256 entityID,
    ILocation expectedDestination,
    ILocation actualDestination
);
error NotReadyToMove(IEntity entity, uint256 entityID, uint64 deadline);
error EntityNotAtLocation(
    IEntity entity,
    uint256 entityID,
    ILocation location,
    ILocation entityLocation
);
