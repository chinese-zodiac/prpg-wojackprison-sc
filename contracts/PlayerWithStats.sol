// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./AccessRoleManager.sol";
import "./BoostedValueCalculator.sol";
import "./interfaces/IEntity.sol";
import "./interfaces/ILocation.sol";

abstract contract PlayerWithStats is ILocation, AccessRoleManager {
    IEntity public immutable player;
    BoostedValueCalculator public boostedValueCalculator;

    constructor(
        IEntity _player,
        BoostedValueCalculator _boostedValueCalculator
    ) {
        player = _player;
        boostedValueCalculator = _boostedValueCalculator;
    }

    modifier onlyPlayerOwner(uint256 playerID) {
        require(msg.sender == player.ownerOf(playerID), "Only player owner");
        _;
    }

    function playerStat(
        uint256 playerID,
        bytes32 statHash
    ) public view returns (uint256) {
        return
            boostedValueCalculator.getBoostedValue(
                this,
                statHash,
                player,
                playerID
            );
    }

    function setBoostedValueCalculator(
        BoostedValueCalculator to
    ) external onlyRole(MANAGER_ROLE) {
        boostedValueCalculator = to;
    }
}
