// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IBooster} from "../interfaces/IBooster.sol";
import {DatastoreEntityERC20} from "../datastores/DatastoreEntityERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {HasRegionSettings} from "../utils/HasRegionSettings.sol";

contract BoosterIERC20Bal is IBooster {
    IERC20 public immutable token;
    DatastoreEntityERC20 public immutable datastoreEntityERC20;
    //Multiples bps by bal then divides by 10,000 ether. 10x is 100,000 bps, 100% is 10,000 bps, and 1% is 100 bps.
    uint256 public immutable bps;

    constructor(
        IERC20 _token,
        DatastoreEntityERC20 _datastoreEntityERC20,
        uint256 _bps
    ) {
        token = _token;
        datastoreEntityERC20 = _datastoreEntityERC20;
        bps = _bps;
    }

    function getBoost(
        ILocation,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 boost) {
        return
            (datastoreEntityERC20.getStoredER20WadFor(entity, entityId, token) *
                bps) / 10000;
    }
}
