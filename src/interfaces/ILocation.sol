// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;
import "./ILocation.sol";
import "./IEntity.sol";

interface ILocation {
    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityID,
        ILocation _from
    ) external;

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) external;

    function viewOnly_getAllValidSources()
        external
        view
        returns (address[] memory locations_);

    function getValidSourceCount() external view returns (uint256);

    function getValidSourceAt(uint256 _i) external view returns (ILocation);

    function viewOnly_getAllValidDestinations()
        external
        view
        returns (address[] memory locations_);

    function getValidDestinationCount() external view returns (uint256);

    function getValidDestinationAt(
        uint256 _i
    ) external view returns (ILocation);

    function viewOnly_getAllValidEntities()
        external
        view
        returns (address[] memory entities_);

    function getValidEntitiesCount() external view returns (uint256);

    function getValidEntitiesAt(uint256 _i) external view returns (IEntity);
}
