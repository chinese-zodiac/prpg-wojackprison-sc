// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;
import "./ILocation.sol";
import "./IEntity.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";

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

    function validSourceSet()
        external
        returns (EnumerableSetAccessControlViewableAddress validSourceSet_);
    function validDestinationSet()
        external
        returns (
            EnumerableSetAccessControlViewableAddress validDestinationSet_
        );
    function validEntitySet()
        external
        returns (EnumerableSetAccessControlViewableAddress validEntitySet_);
}
