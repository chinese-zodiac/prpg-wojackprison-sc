// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {GlobalSettings} from "../GlobalSettings.sol";
import {IEntity} from "./IEntity.sol";

interface IExecutor {
    function globalSettings() external returns (GlobalSettings);
    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        bytes32 _actionKey,
        bytes calldata _param
    ) external;
    function revertIfAccountBlacklisted(address account) external view;
    function revertIfEntityOwnerBlacklisted(
        IEntity _entity,
        uint256 _entityID
    ) external view;
}
