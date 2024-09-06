// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {EntityStoreERC20} from "../EntityStoreERC20.sol";
import {TokenBase} from "../TokenBase.sol";
import {LocPlayerWithStats} from "./LocPlayerWithStats.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ResourceStakingPool} from "../ResourceStakingPool.sol";

abstract contract LocResource is LocPlayerWithStats {
    bytes32 public constant BOOSTER_PLAYER_PULL_ADD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PULL_ADD"));
    bytes32 public constant BOOSTER_PLAYER_PULL_MUL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PULL_MUL"));
    bytes32 public constant BOOSTER_PLAYER_PROD_DAILY_ADD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PROD_DAILY_ADD"));
    bytes32 public constant BOOSTER_PLAYER_PROD_DAILY_MUL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PROD_DAILY_MUL"));

    TokenBase public resourceToken;

    uint256 public baseProdDaily;
    uint256 public currentProdDaily;
    mapping(uint256 playerID => uint256 prodDaily) public playerProdDaily;

    ResourceStakingPool public resourceStakingPool;

    event SetBaseProdDaily(uint256 baseProdDaily);
    event SetCurrentProdDaily(uint256 currentProdDaily);
    event SetPlayerProdDaily(uint256 playerID, uint256 playerProdDaily);
    event SetResourceStakingPool(ResourceStakingPool resourceStakingPool);
    event SetResourceToken(TokenBase resourceToken);

    constructor(TokenBase _resourceToken, uint256 _baseProdDaily) {
        baseProdDaily = _baseProdDaily;
        currentProdDaily = _baseProdDaily;
        resourceToken = _resourceToken;

        resourceStakingPool = new ResourceStakingPool(
            _resourceToken,
            _baseProdDaily / 24 hours,
            address(this)
        );

        emit SetBaseProdDaily(baseProdDaily);
        emit SetCurrentProdDaily(currentProdDaily);
        emit SetResourceStakingPool(resourceStakingPool);
        emit SetResourceToken(resourceToken);
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
        EntityStoreERC20 erc20Store = regionSettings.entityStoreERC20();
        resourceToken.approve(address(erc20Store), deltabal);
        erc20Store.deposit(
            regionSettings.player(),
            playerID,
            resourceToken,
            deltabal
        );
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityId,
        ILocation //_from
    ) public virtual override {
        if (_entity == regionSettings.player()) {
            _startPlayerProduction(_entityId);
        }
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityId,
        ILocation //_to
    ) public virtual override {
        if (_entity == regionSettings.player()) {
            _haltPlayerProduction(_entityId);
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

    function setResourceStakingPool(
        ResourceStakingPool to
    ) external onlyManager {
        resourceStakingPool = to;
        emit SetResourceStakingPool(resourceStakingPool);
    }

    function setResourceToken(TokenBase to) external onlyManager {
        resourceToken = to;
        resourceStakingPool.setRewardToken(to);
        emit SetResourceToken(resourceToken);
    }

    function setBaseResourcesPerDay(uint256 to) external onlyManager {
        currentProdDaily -= baseProdDaily;
        baseProdDaily = to;
        currentProdDaily += baseProdDaily;
        emit SetBaseProdDaily(baseProdDaily);
        emit SetCurrentProdDaily(currentProdDaily);
    }

    function _haltPlayerProduction(uint256 playerID) internal {
        _claimPendingResources(playerID);
        resourceStakingPool.setRewardPerSecond(currentProdDaily / 24 hours);
        resourceStakingPool.withdrawFor(bytes32(playerID));
        currentProdDaily -= playerProdDaily[playerID];
        delete playerProdDaily[playerID];
        emit SetCurrentProdDaily(currentProdDaily);
        emit SetPlayerProdDaily(playerID, 0);
    }

    function _startPlayerProduction(uint256 playerID) internal {
        uint256 pull = playerStat(
            playerID,
            BOOSTER_PLAYER_PULL_ADD,
            BOOSTER_PLAYER_PULL_MUL
        );
        playerProdDaily[playerID] = playerStat(
            playerID,
            BOOSTER_PLAYER_PROD_DAILY_ADD,
            BOOSTER_PLAYER_PROD_DAILY_MUL
        );
        currentProdDaily += playerProdDaily[playerID];

        resourceStakingPool.setRewardPerSecond(currentProdDaily / 24 hours);
        resourceStakingPool.depositFor(bytes32(playerID), pull);
        emit SetCurrentProdDaily(currentProdDaily);
        emit SetPlayerProdDaily(playerID, playerProdDaily[playerID]);
    }
}
