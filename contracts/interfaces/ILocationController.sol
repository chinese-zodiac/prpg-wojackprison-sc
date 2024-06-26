// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;
import "./ILocation.sol";
import "./IEntity.sol";

interface ILocationController {
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

    //High gas usage, view only
    function viewOnly_getAllLocalEntitiesFor(
        ILocation _location,
        IEntity _entity
    ) external view returns (uint256[] memory entityIds_);

    function getEntityLocation(
        IEntity _entity,
        uint256 _entityId
    ) external view returns (ILocation);

    function getLocalEntityCountFor(
        ILocation _location,
        IEntity _entity
    ) external view returns (uint256);

    function getLocalEntityAtIndexFor(
        ILocation _location,
        IEntity _entity,
        uint256 _i
    ) external view returns (uint256 entityId_);
}
