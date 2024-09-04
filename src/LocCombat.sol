// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;
import "./LocationBase.sol";
import "./LocWithTokenStore.sol";
import "./PlayerWithStats.sol";
import "./libs/Timers.sol";
import "./libs/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract LocCombat is
    LocationBase,
    PlayerWithStats,
    LocWithTokenStore
{
    using Counters for Counters.Counter;
    using Timers for Timers.Timestamp;
    using SafeERC20 for IERC20;

    bytes32 public constant BOOSTER_PLAYER_POWER =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_POWER"));
    bytes32 public constant BOOSTER_PLAYER_ATKCD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_ATKCD"));
    mapping(uint256 => Timers.Timestamp) public playerAttackTimer;

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
    mapping(uint256 => Attack) attackLog;
    Counters.Counter attackLogNextUid;

    ERC20Burnable public combatToken;

    event AttackResolved(
        IEntity player,
        uint256 attackerPlayerID,
        uint256 defenderPlayerID,
        IERC20 combatToken,
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
                    playerStat(attackerPlayerID, BOOSTER_PLAYER_ATKCD)
            )
        ); //attackcooldown should be set by booster

        Attack storage currentAttack = attackLog[attackLogNextUid.current()];
        attackLogNextUid.increment();
        currentAttack.attackerPlayerID = attackerPlayerID;
        currentAttack.defenderPlayerID = defenderPlayerID;
        currentAttack.time = block.timestamp;
        uint256 attackerTokens = entityStoreERC20.getStoredER20WadFor(
            player,
            attackerPlayerID,
            combatToken
        );
        uint256 defenderTokens = entityStoreERC20.getStoredER20WadFor(
            player,
            defenderPlayerID,
            combatToken
        );
        uint256 attackerPowerPerToken = (playerStat(
            attackerPlayerID,
            BOOSTER_PLAYER_POWER
        ) * 1 ether) / attackerTokens;
        uint256 defenderPowerPerToken = (playerStat(
            defenderPlayerID,
            BOOSTER_PLAYER_POWER
        ) * 1 ether) / defenderTokens;
        uint256 powerRatio = (1 ether * attackerPowerPerToken) /
            defenderPowerPerToken;

        //Destroy the combatToken cost from attacker
        currentAttack.cost = (attackCostBps * attackerTokens) / 10000;
        if (currentAttack.cost > 0) {
            entityStoreERC20.burn(
                player,
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
                player,
                defenderPlayerID,
                player,
                attackerPlayerID,
                combatToken,
                currentAttack.winnings
            );
        }

        emit AttackResolved(
            player,
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
