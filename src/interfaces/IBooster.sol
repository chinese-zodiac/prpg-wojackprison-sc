// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import "./IEntity.sol";

interface IBooster {
    function getBoost(
        uint256 locId,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 boost);
}
