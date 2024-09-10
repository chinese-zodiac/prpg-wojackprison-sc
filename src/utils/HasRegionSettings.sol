// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {RegionSettings} from "../RegionSettings.sol";
import {AccessRoleManager} from "../AccessRoleManager.sol";
import {IHasRegionSettings} from "../interfaces/IHasRegionSettings.sol";

contract HasRegionSettings is IHasRegionSettings, AccessRoleManager {
    RegionSettings public regionSettings;
    event SetRegionSettings(RegionSettings regionSettings);

    constructor(RegionSettings _regionSettings) {
        regionSettings = _regionSettings;
        emit SetRegionSettings(regionSettings);
    }

    function setRegionSettings(
        RegionSettings _regionSettings
    ) external onlyManager {
        regionSettings = _regionSettings;
        emit SetRegionSettings(regionSettings);
    }
}
