// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IEntity} from "./interfaces/IEntity.sol";
import {LocationBase} from "./LocationBase.sol";
import {LocWithTokenStore} from "./LocWithTokenStore.sol";
import {LocPlayerWithStats} from "./LocPlayerWithStats.sol";
import {Timers} from "./libs/Timers.sol";
import {Counters} from "./libs/Counters.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract LocCombat is
    LocationBase,
    LocPlayerWithStats,
    LocWithTokenStore
{
    using Counters for Counters.Counter;
    using Timers for Timers.Timestamp;

    bytes32 public constant BOOSTER_PLAYER_POWER_ADD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_POWER_ADD"));
    bytes32 public constant BOOSTER_PLAYER_POWER_MUL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_POWER_MUL"));
    bytes32 public constant BOOSTER_PLAYER_ATKCD_ADD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_ATKCD_ADD"));
    bytes32 public constant BOOSTER_PLAYER_ATKCD_MUL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_ATKCD_MUL"));
    mapping(uint256 attackID => Timers.Timestamp attackTimer)
        public playerAttackTimer;

    //attackCD is consumed by a booster
    uint64 public attackCooldown = 4 hours;
    uint256 public attackCostBps = 200;
    uint256 public victoryTransferBps = 1000;

    struct Attack {
        uint256 attackerPlayerID;
        uint256 defenderPlayerID;
        uint256 cost;
        uint256 winnings;
        uint256 time;
    }
    mapping(uint256 attackId => Attack log) attackLog;
    Counters.Counter attackLogNextUid;

    ERC20Burnable public combatToken;

    event AttackResolved(
        IEntity player,
        uint256 attackerPlayerID,
        uint256 defenderPlayerID,
        ERC20Burnable combatToken,
        uint256 attackCostWad,
        uint256 attackWinningsWad
    );

    constructor(ERC20Burnable _combatToken) {
        combatToken = _combatToken;
    }

    function attack(
        uint256 attackerPlayerID,
        uint256 defenderPlayerID
    ) public virtual onlyPlayerOwner(attackerPlayerID) {
        require(attackerPlayerID != defenderPlayerID, "Cannot attack self");
        require(
            playerAttackTimer[attackerPlayerID].isExpired() ||
                playerAttackTimer[attackerPlayerID].isUnset(),
            "Attack on cooldown"
        );
        playerAttackTimer[attackerPlayerID].setDeadline(
            uint64(
                block.timestamp +
                    playerStat(
                        attackerPlayerID,
                        BOOSTER_PLAYER_ATKCD_ADD,
                        BOOSTER_PLAYER_ATKCD_MUL
                    )
            )
        ); //attackcooldown should be set by booster

        Attack storage currentAttack = attackLog[attackLogNextUid.current()];
        attackLogNextUid.increment();
        currentAttack.attackerPlayerID = attackerPlayerID;
        currentAttack.defenderPlayerID = defenderPlayerID;
        currentAttack.time = block.timestamp;
        uint256 attackerTokens = entityStoreERC20.getStoredER20WadFor(
            PLAYER,
            attackerPlayerID,
            combatToken
        );
        uint256 defenderTokens = entityStoreERC20.getStoredER20WadFor(
            PLAYER,
            defenderPlayerID,
            combatToken
        );
        uint256 attackerPowerPerToken = (playerStat(
            attackerPlayerID,
            BOOSTER_PLAYER_POWER_ADD,
            BOOSTER_PLAYER_POWER_MUL
        ) * 1 ether) / attackerTokens;
        uint256 defenderPowerPerToken = (playerStat(
            defenderPlayerID,
            BOOSTER_PLAYER_POWER_ADD,
            BOOSTER_PLAYER_POWER_MUL
        ) * 1 ether) / defenderTokens;
        uint256 powerRatio = (1 ether * attackerPowerPerToken) /
            defenderPowerPerToken;

        //Destroy the combatToken cost from attacker
        currentAttack.cost = (attackCostBps * attackerTokens) / 10000;
        if (currentAttack.cost > 0) {
            entityStoreERC20.burn(
                PLAYER,
                attackerPlayerID,
                combatToken,
                currentAttack.cost
            );
        }

        //victory
        currentAttack.winnings =
            (victoryTransferBps * defenderTokens * powerRatio) /
            10000 ether;

        if (currentAttack.winnings > 0) {
            entityStoreERC20.transfer(
                PLAYER,
                defenderPlayerID,
                PLAYER,
                attackerPlayerID,
                combatToken,
                currentAttack.winnings
            );
        }

        emit AttackResolved(
            PLAYER,
            attackerPlayerID,
            defenderPlayerID,
            combatToken,
            currentAttack.cost,
            currentAttack.winnings
        );
    }

    //High gas usage, view only
    function viewOnly_getAllAttackLog()
        external
        view
        returns (Attack[] memory attacks)
    {
        attacks = new Attack[](attackLogNextUid.current());
        for (uint i; i < attackLogNextUid.current(); i++) {
            attacks[i] = attackLog[i];
        }
    }

    function getAttackLogLength() public view returns (uint256) {
        return attackLogNextUid.current();
    }

    function getAttackAt(uint256 index) public view returns (Attack memory) {
        return attackLog[index];
    }

    function playerAttackCooldown(
        uint256 playerID
    ) external view returns (uint256) {
        return playerAttackTimer[playerID].getDeadline();
    }

    function setAttackCostBps(uint64 to) external onlyManager {
        attackCostBps = to;
    }

    function setVictoryTransferBps(uint64 to) external onlyManager {
        victoryTransferBps = to;
    }

    function setAttackCooldown(uint64 to) external onlyManager {
        attackCooldown = to;
    }
}
