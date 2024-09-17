// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IEntity} from "../interfaces/IEntity.sol";
import {HasRegionSettings} from "./HasRegionSettings.sol";
import {RegionSettings} from "../RegionSettings.sol";

contract HasRSBlacklist is HasRegionSettings {
    modifier blacklisted() {
        revertIfAccountBlacklisted(msg.sender);
        _;
    }

    modifier blacklistedEntity(IEntity _entity, uint256 _entityID) {
        revertIfAccountBlacklisted(_entity.ownerOf(_entityID));
        _;
    }

    constructor(RegionSettings _rs) HasRegionSettings(_rs) {}

    function revertIfAccountBlacklisted(address account) public view {
        regionSettings.tenXBlacklist().revertIfAccountBlacklisted(account);
    }

    function revertIfEntityOwnerBlacklisted(
        IEntity _entity,
        uint256 _entityID
    ) external view {
        revertIfAccountBlacklisted(_entity.ownerOf(_entityID));
    }
}
