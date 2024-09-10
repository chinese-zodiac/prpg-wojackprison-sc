// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.23;
import {RegionSettings} from "../RegionSettings.sol";

interface IHasRegionSettings {
    function regionSettings()
        external
        view
        returns (RegionSettings regionSettings);
}
