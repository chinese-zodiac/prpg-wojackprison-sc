// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessRoleManager} from "./AccessRoleManager.sol";
import {BoostedValueCalculator} from "./BoostedValueCalculator.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";

abstract contract LocPlayerWithStats is ILocation, AccessRoleManager {
    IEntity public immutable PLAYER;
    BoostedValueCalculator public boostedValueCalculator;

    event SetBoostedValueCalculator(
        BoostedValueCalculator boostedValueCalculator
    );

    error OnlyPlayerOwner(uint256 playerID, address sender);

    constructor(
        IEntity _player,
        BoostedValueCalculator _boostedValueCalculator
    ) {
        PLAYER = _player;
        boostedValueCalculator = _boostedValueCalculator;
        emit SetBoostedValueCalculator(boostedValueCalculator);
    }

    modifier onlyPlayerOwner(uint256 playerID) {
        if (PLAYER.ownerOf(playerID) != msg.sender) {
            revert OnlyPlayerOwner(playerID, msg.sender);
        }
        _;
    }

    function playerStat(
        uint256 playerID,
        bytes32 statHashAdd,
        bytes32 statHashMul
    ) public view returns (uint256) {
        return
            boostedValueCalculator.getBoosterAccSum(
                this,
                statHashAdd,
                PLAYER,
                playerID
            ) *
            boostedValueCalculator.getBoosterAccMul(
                this,
                statHashMul,
                PLAYER,
                playerID
            );
    }

    function setBoostedValueCalculator(
        BoostedValueCalculator to
    ) external onlyRole(MANAGER_ROLE) {
        boostedValueCalculator = to;
        emit SetBoostedValueCalculator(boostedValueCalculator);
    }
}
