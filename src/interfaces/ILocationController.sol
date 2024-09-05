// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.23;
import {ILocation} from "./ILocation.sol";
import {IEntity} from "./IEntity.sol";
import {EnumerableSetAccessControlViewableUint256} from "../utils/EnumerableSetAccessControlViewableUint256.sol";

interface ILocationController {
    function locationEntityIdSet(
        ILocation location,
        IEntity entity
    )
        external
        view
        returns (EnumerableSetAccessControlViewableUint256 entityIdSet);
    function entityIdLocation(
        IEntity entity,
        uint256 entityID
    ) external view returns (ILocation location);

    //Moves entity from current location to new location.
    //Must call LOCATION_CONTROLLER_onDeparture for old ILocation
    //Must call LOCATION_CONTROLLER_onArrival for new ILocation
    function move(IEntity _entity, uint256 _entityId, ILocation _dest) external;

    //Must call LOCATION_CONTROLLER_onArrival for new ILocation
    function spawn(
        IEntity _entity,
        uint256 _entityId,
        ILocation _dest
    ) external;

    //Must call LOCATION_CONTROLLER_onDeparture for old ILocation
    function despawn(IEntity _entity, uint256 _entityId) external;
}
