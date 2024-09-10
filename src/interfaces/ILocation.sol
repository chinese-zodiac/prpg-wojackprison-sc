// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.23;
import {IEntity} from "./IEntity.sol";
import {IActionController} from "./IActionController.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";
import {IHasRegionSettings} from "./IHasRegionSettings.sol";
import {IAuthorizer} from "./IAuthorizer.sol";

interface ILocation is IHasRegionSettings, IAuthorizer {
    function acSet()
        external
        view
        returns (EnumerableSetAccessControlViewableAddress set);
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType
    ) external;
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        address _param
    ) external;
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        uint256 _param
    ) external;
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        bytes32 _param
    ) external;
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        bytes[] calldata _param
    ) external;
    function addActionController(IActionController _ac) external;
    function deleteActionController(IActionController _ac) external;
}
