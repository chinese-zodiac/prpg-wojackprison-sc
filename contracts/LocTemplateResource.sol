// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./LocationBase.sol";
import "./TokenBase.sol";
import "./BoostedValueCalculator.sol";
import "./interfaces/IEntity.sol";
import "./EntityStoreERC20.sol";
import "./ResourceStakingPool.sol";
import "./libs/Timers.sol";
import "./libs/Counters.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LocTemplateResource is LocationBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Timers for Timers.Timestamp;
    using SafeERC20 for IERC20;

    bytes32 public constant BOOSTER_PLAYER_PULL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PULL"));
    bytes32 public constant BOOSTER_PLAYER_PROD_DAILY =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PROD_DAILY"));
    bytes32 public constant BOOSTER_PLAYER_POWER =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_POWER"));
    bytes32 public constant BOOSTER_PLAYER_ATKCD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_ATKCD"));
    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME"));

    EntityStoreERC20 public entityStoreERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    ERC20Burnable public combatToken;

    //travelTime is consumed by a booster
    uint64 public travelTime = 4 hours;
    IEntity public player;

    TokenBase public resourceToken;

    uint256 public baseProdDaily;
    uint256 public currentProdDaily;
    mapping(uint256 playerID => uint256 prodDaily) public playerProdDaily;

    mapping(uint256 => Timers.Timestamp) public playerAttackTimer;

    //attackCD is consumed by a booster
    uint64 public attackCooldown = 4 hours;
    uint256 public attackCostBps = 200;
    uint256 public victoryTransferBps = 1000;

    BoostedValueCalculator public boostedValueCalculator;
    ResourceStakingPool public resourceStakingPool;

    struct MovementPreparation {
        Timers.Timestamp readyTimer;
        ILocation destination;
    }
    mapping(uint256 => MovementPreparation) playerMovementPreparations;

    struct Attack {
        uint256 attackerPlayerID;
        uint256 defenderPlayerID;
        uint256 cost;
        uint256 winnings;
        uint256 time;
    }
    mapping(uint256 => Attack) attackLog;
    Counters.Counter attackLogNextUid;

    EnumerableSet.AddressSet fixedDestinations;

    constructor(
        ILocationController _locationController,
        EntityStoreERC20 _entityStoreERC20,
        IEntity _player,
        ERC20Burnable _combatToken,
        BoostedValueCalculator _boostedValueCalculator,
        TokenBase _resourceToken,
        uint256 _baseProdDaily
    ) LocationBase(_locationController) {
        entityStoreERC20 = _entityStoreERC20;
        baseProdDaily = _baseProdDaily;
        currentProdDaily = _baseProdDaily;
        boostedValueCalculator = _boostedValueCalculator;
        resourceToken = _resourceToken;
        player = _player;
        combatToken = _combatToken;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(VALID_ENTITY_SETTER, msg.sender);

        resourceStakingPool = new ResourceStakingPool(
            _resourceToken,
            _baseProdDaily / 24 hours,
            address(this)
        );
    }

    modifier onlyPlayerOwner(uint256 playerID) {
        require(msg.sender == player.ownerOf(playerID), "Only player owner");
        _;
    }

    function claimPendingResources(
        uint256 playerID
    ) external onlyPlayerOwner(playerID) {
        _claimPendingResources(playerID);
    }

    function _claimPendingResources(uint256 playerID) internal {
        if (resourceStakingPool.pendingReward(bytes32(playerID)) == 0) {
            return;
        }
        uint256 initialResourceBal = resourceToken.balanceOf(address(this));
        resourceStakingPool.claimFor(bytes32(playerID));
        uint256 deltabal = resourceToken.balanceOf(address(this)) -
            initialResourceBal;
        resourceToken.approve(address(entityStoreERC20), deltabal);
        entityStoreERC20.deposit(player, playerID, resourceToken, deltabal);
    }

    function attack(
        uint256 attackerPlayerID,
        uint256 defenderPlayerID
    )
        public
        onlyLocalEntity(player, attackerPlayerID)
        onlyLocalEntity(player, defenderPlayerID)
        onlyPlayerOwner(attackerPlayerID)
    {
        require(attackerPlayerID != defenderPlayerID, "Cannot attack self");
        require(
            playerAttackTimer[attackerPlayerID].isExpired() ||
                playerAttackTimer[attackerPlayerID].isUnset(),
            "Attack on cooldown"
        );
        require(isPlayerWorking(attackerPlayerID), "Attacker not working");
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
        _haltPlayerProduction(defenderPlayerID);
        _startPlayerProduction(defenderPlayerID);

        _haltPlayerProduction(attackerPlayerID);
        _startPlayerProduction(attackerPlayerID);
    }

    function prepareToMovePlayerToFixedDestination(
        uint256 playerID,
        ILocation destination
    ) external onlyLocalEntity(player, playerID) onlyPlayerOwner(playerID) {
        require(fixedDestinations.contains(address(destination)));
        playerMovementPreparations[playerID].destination = destination;
        _prepareMove(playerID);
    }

    function _prepareMove(uint256 playerID) internal {
        playerMovementPreparations[playerID].readyTimer.setDeadline(
            uint64(
                block.timestamp +
                    playerStat(playerID, BOOSTER_PLAYER_TRAVELTIME)
            )
        );
        _haltPlayerProduction(playerID);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IERC721 _entity,
        uint256 _entityId,
        ILocation _from
    ) external virtual override {
        require(msg.sender == address(locationController), "Sender must be LC");
        require(validSources.contains(address(_from)), "Invalid source");
        require(validEntities.contains(address(_entity)), "Invalid entity");
        if (_entity == player) {
            _startPlayerProduction(_entityId);
        }
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IERC721 _entity,
        uint256 _entityId,
        ILocation _to
    ) external virtual override {
        require(msg.sender == address(locationController), "Sender must be LC");
        require(
            validDestinations.contains(address(_to)),
            "Invalid destination"
        );
        require(validEntities.contains(address(_entity)), "Invalid entity");
        if (_entity == player) {
            //Only let prepared entities go
            require(isPlayerReadyToMove(_entityId), "Player not ready to move");
            //Only go to prepared destination
            require(
                _to == playerDestination(_entityId),
                "Player not prepared to travel there"
            );

            //reset timer
            playerMovementPreparations[_entityId].readyTimer.reset();
        }
    }

    function pendingResources(
        uint256 playerID
    ) external view returns (uint256) {
        return resourceStakingPool.pendingReward(bytes32(playerID));
    }

    function playerPull(uint256 playerID) public view returns (uint256) {
        return resourceStakingPool.getShares(bytes32(playerID));
    }

    function totalPull() public view returns (uint256) {
        return resourceStakingPool.totalShares();
    }

    function playerResourcesPerDay(
        uint256 playerID
    ) external view returns (uint256) {
        if (totalPull() == 0) return 0;
        return (playerPull(playerID) * currentProdDaily) / totalPull();
    }

    function playerDestination(
        uint256 playerID
    ) public view returns (ILocation) {
        return playerMovementPreparations[playerID].destination;
    }

    function playerAttackCooldown(
        uint256 playerID
    ) external view returns (uint256) {
        return playerAttackTimer[playerID].getDeadline();
    }

    function isPlayerPreparingToMove(
        uint256 playerID
    ) public view returns (bool) {
        return
            playerMovementPreparations[playerID].readyTimer.isPending() ||
            isPlayerReadyToMove(playerID);
    }

    function isPlayerReadyToMove(uint256 playerID) public view returns (bool) {
        return playerMovementPreparations[playerID].readyTimer.isExpired();
    }

    function isPlayerWorking(uint256 playerID) public view returns (bool) {
        return
            playerMovementPreparations[playerID].readyTimer.isUnset() &&
            locationController.getEntityLocation(player, playerID) == this;
    }

    function whenPlayerIsReadyToMove(
        uint256 playerID
    ) public view returns (uint64) {
        return playerMovementPreparations[playerID].readyTimer.getDeadline();
    }

    //High gas usage, view only
    function viewOnly_getAllFixedDestinations()
        external
        view
        returns (address[] memory destinations_)
    {
        destinations_ = fixedDestinations.values();
    }

    function getFixedDestinationsCount() public view returns (uint256) {
        return fixedDestinations.length();
    }

    function getFixedDestinationAt(uint256 _i) public view returns (address) {
        return fixedDestinations.at(_i);
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

    function setFixedDestinations(
        address[] calldata _destinations,
        bool isDestination
    ) public onlyRole(MANAGER_ROLE) {
        if (isDestination) {
            for (uint i; i < _destinations.length; i++) {
                fixedDestinations.add(_destinations[i]);
                validDestinations.add(_destinations[i]);
                validSources.add(_destinations[i]);
            }
        } else {
            for (uint i; i < _destinations.length; i++) {
                fixedDestinations.remove(_destinations[i]);
                validDestinations.remove(_destinations[i]);
                validSources.remove(_destinations[i]);
            }
        }
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

    function setResourceStakingPool(
        ResourceStakingPool to
    ) external onlyRole(MANAGER_ROLE) {
        resourceStakingPool = to;
    }

    function setResourceToken(TokenBase to) external onlyRole(MANAGER_ROLE) {
        resourceToken = to;
        resourceStakingPool.setRewardToken(to);
    }

    function setAttackCostBps(uint64 to) external onlyRole(MANAGER_ROLE) {
        attackCostBps = to;
    }

    function setVictoryTransferBps(uint64 to) external onlyRole(MANAGER_ROLE) {
        victoryTransferBps = to;
    }

    function setAttackCooldown(uint64 to) external onlyRole(MANAGER_ROLE) {
        attackCooldown = to;
    }

    function setTravelTime(uint64 to) external onlyRole(MANAGER_ROLE) {
        travelTime = to;
    }

    function setBaseResourcesPerDay(
        uint256 to
    ) external onlyRole(MANAGER_ROLE) {
        currentProdDaily -= baseProdDaily;
        baseProdDaily = to;
        currentProdDaily += baseProdDaily;
    }

    function _haltPlayerProduction(uint256 playerID) internal {
        _claimPendingResources(playerID);
        resourceStakingPool.setRewardPerSecond(currentProdDaily / 24 hours);
        resourceStakingPool.withdrawFor(bytes32(playerID));
        currentProdDaily -= playerProdDaily[playerID];
        delete playerProdDaily[playerID];
    }

    function _startPlayerProduction(uint256 playerID) internal {
        uint256 pull = playerStat(playerID, BOOSTER_PLAYER_PULL);
        playerProdDaily[playerID] = playerStat(
            playerID,
            BOOSTER_PLAYER_PROD_DAILY
        );
        currentProdDaily += playerProdDaily[playerID];

        resourceStakingPool.setRewardPerSecond(currentProdDaily / 24 hours);
        resourceStakingPool.depositFor(bytes32(playerID), pull);
    }
}
