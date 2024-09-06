// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {LocBase} from "./LocBase.sol";
import {BoostedValueCalculator} from "../BoostedValueCalculator.sol";
import {IEntity} from "../interfaces/IEntity.sol";

abstract contract LocPlayerWithStats is LocBase {
    error OnlyPlayerOwner(uint256 playerID, address sender);

    modifier onlyPlayerOwner(uint256 playerID) {
        if (regionSettings.player().ownerOf(playerID) != msg.sender) {
            revert OnlyPlayerOwner(playerID, msg.sender);
        }
        _;
    }

    function playerStat(
        uint256 playerID,
        bytes32 statHashAdd,
        bytes32 statHashMul
    ) public view returns (uint256) {
        IEntity player = regionSettings.player();
        BoostedValueCalculator bcalc = regionSettings.boostedValueCalculator();
        return
            bcalc.getBoosterAccSum(this, statHashAdd, player, playerID) *
            bcalc.getBoosterAccMul(this, statHashMul, player, playerID);
    }
}
