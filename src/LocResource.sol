// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./PlayerWithStats.sol";
import "./interfaces/IEntity.sol";
import "./ResourceStakingPool.sol";
import "./LocWithTokenStore.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract LocResource is ILocation, PlayerWithStats, LocWithTokenStore {
    using SafeERC20 for IERC20;

    bytes32 public constant BOOSTER_PLAYER_PULL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PULL"));
    bytes32 public constant BOOSTER_PLAYER_PROD_DAILY =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_PROD_DAILY"));

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
        resourceToken.approve(address(entityStoreERC20), deltabal);
        entityStoreERC20.deposit(player, playerID, resourceToken, deltabal);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityId,
        ILocation //_from
    ) public virtual override {
        if (_entity == player) {
            _startPlayerProduction(_entityId);
        }
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityId,
        ILocation //_to
    ) public virtual override {
        if (_entity == player) {
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
    ) external onlyRole(MANAGER_ROLE) {
        resourceStakingPool = to;
        emit SetResourceStakingPool(resourceStakingPool);
    }

    function setResourceToken(TokenBase to) external onlyRole(MANAGER_ROLE) {
        resourceToken = to;
        resourceStakingPool.setRewardToken(to);
        emit SetResourceToken(resourceToken);
    }

    function setBaseResourcesPerDay(
        uint256 to
    ) external onlyRole(MANAGER_ROLE) {
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
        uint256 pull = playerStat(playerID, BOOSTER_PLAYER_PULL);
        playerProdDaily[playerID] = playerStat(
            playerID,
            BOOSTER_PLAYER_PROD_DAILY
        );
        currentProdDaily += playerProdDaily[playerID];

        resourceStakingPool.setRewardPerSecond(currentProdDaily / 24 hours);
        resourceStakingPool.depositFor(bytes32(playerID), pull);
        emit SetCurrentProdDaily(currentProdDaily);
        emit SetPlayerProdDaily(playerID, playerProdDaily[playerID]);
    }
}
