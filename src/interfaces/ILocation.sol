// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.23;
import {IEntity} from "./IEntity.sol";
import {IAction} from "./IAction.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import {IHasRegionSettings} from "./IHasRegionSettings.sol";
import {IAuthorizer} from "./IAuthorizer.sol";

interface ILocation is IHasRegionSettings, IAuthorizer {
    function SETTER_ROLE() external returns (bytes32);
    function actionSet()
        external
        view
        returns (EnumerableSetAccessControlViewableBytes32 set);
    function actions(
        bytes32 _actionKey
    ) external view returns (IAction _action);
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        bytes32 _actionKey,
        bytes calldata _param
    ) external;
    function commitToDatastore(address _ds, bytes calldata _data) external;
    function addAction(IAction _action) external;
    function deleteAction(IAction _action) external;
}
