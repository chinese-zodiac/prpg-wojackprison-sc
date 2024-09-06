// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {RegionSettings} from "../RegionSettings.sol";
import {AccessRoleManager} from "../AccessRoleManager.sol";

contract HasRegionSettings is AccessRoleManager {
    RegionSettings public regionSettings;
    event SetRegionSettings(RegionSettings regionSettings);

    constructor(RegionSettings _regionSettings) {
        regionSettings = _regionSettings;
        emit SetRegionSettings(regionSettings);
    }

    function setGovernance(
        RegionSettings _regionSettings
    ) external onlyManager {
        regionSettings = _regionSettings;
        emit SetRegionSettings(regionSettings);
    }
}
