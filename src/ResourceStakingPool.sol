// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Olive.cash, Pancakeswap
pragma solidity ^0.8.23;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenBase} from "./TokenBase.sol";

//import "hardhat/console.sol";

contract ResourceStakingPool is Ownable {
    using SafeERC20 for IERC20;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The timestamp of the last pool update
    uint256 public timestampLast;

    // REWARD tokens created per second.
    uint256 public rewardPerSecond;

    // The precision factor
    uint256 public immutable PRECISION_FACTOR;

    // The reward token
    TokenBase public rewardToken;

    //Total shares
    uint256 public totalShares;

    // Info of each entity that stakes tokens (stakedToken)
    mapping(bytes32 entityID => EntityInfo entityInfo) public entityInfo;

    event Deposit(bytes32 entityId, uint256 shares);
    event Withdraw(bytes32 entityId, uint256 shares);
    event Claim(bytes32 entityId, uint256 pending);
    event Update(uint256 accTokenPerShare);
    event SetRPS(uint256 rewardPerSecond);
    event SetRewardToken(TokenBase rewardToken);

    struct EntityInfo {
        uint256 shares; // How many shares in the pool the user owns
        uint256 rewardDebt; // Reward debt
    }

    constructor(
        TokenBase _rewardToken,
        uint256 _rewardPerSecond,
        address _admin
    ) Ownable(_admin) {
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        timestampLast = block.timestamp;
        emit SetRewardToken(rewardToken);
        emit SetRPS(rewardPerSecond);

        PRECISION_FACTOR = uint256(
            10 **
                (uint256(30) -
                    (IERC20Metadata(address(_rewardToken)).decimals()))
        );
    }

    function depositFor(
        bytes32 entityId,
        uint256 shares
    ) public onlyOwner returns (uint256 claim) {
        emit Deposit(entityId, shares);
        EntityInfo storage entity = entityInfo[entityId];

        _updatePool();

        if (entity.shares > 0) {
            uint256 pending = (entity.shares * accTokenPerShare) /
                PRECISION_FACTOR -
                entity.rewardDebt;
            if (pending > 0) {
                rewardToken.mint(owner(), pending);
                claim = pending;
                emit Claim(entityId, pending);
            }
        }

        if (shares > 0) {
            entity.shares += shares;
            totalShares += shares;
        }

        entity.rewardDebt =
            (entity.shares * accTokenPerShare) /
            PRECISION_FACTOR;
    }

    /*
     * @notice Claim staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function claimFor(
        bytes32 entityId
    ) external onlyOwner returns (uint256 claim) {
        EntityInfo storage entity = entityInfo[entityId];

        _updatePool();

        uint256 pending = (entity.shares * accTokenPerShare) /
            PRECISION_FACTOR -
            entity.rewardDebt;

        if (pending > 0) {
            rewardToken.mint(owner(), pending);
            claim = pending;
            emit Claim(entityId, pending);
        }

        entity.rewardDebt =
            (entity.shares * accTokenPerShare) /
            PRECISION_FACTOR;
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(
        bytes32 entityId
    ) external view returns (uint256 claimable) {
        EntityInfo storage entity = entityInfo[entityId];
        if (block.timestamp > timestampLast && totalShares != 0) {
            uint256 multiplier = block.timestamp - timestampLast;
            uint256 tokenReward = multiplier * rewardPerSecond;
            uint256 adjustedTokenPerShare = accTokenPerShare +
                ((tokenReward * PRECISION_FACTOR) / totalShares);
            return
                (entity.shares * adjustedTokenPerShare) /
                PRECISION_FACTOR -
                entity.rewardDebt;
        } else {
            return
                (entity.shares * accTokenPerShare) /
                PRECISION_FACTOR -
                entity.rewardDebt;
        }
    }

    function entityResourcePerSecond(
        bytes32 entityId
    ) external view returns (uint256 rate) {
        EntityInfo storage entity = entityInfo[entityId];
        if (block.timestamp > timestampLast && totalShares != 0) {
            uint256 multiplier = 1;
            uint256 tokenReward = multiplier * rewardPerSecond;
            uint256 adjustedTokenPerShare = accTokenPerShare +
                ((tokenReward * PRECISION_FACTOR) / totalShares);
            return
                (entity.shares * adjustedTokenPerShare) /
                PRECISION_FACTOR -
                entity.rewardDebt;
        } else {
            return
                (entity.shares * accTokenPerShare) /
                PRECISION_FACTOR -
                entity.rewardDebt;
        }
    }

    function withdrawFor(
        bytes32 entityId
    ) external onlyOwner returns (uint256 claim) {
        EntityInfo storage entity = entityInfo[entityId];

        uint256 shares = entity.shares;
        emit Withdraw(entityId, shares);

        _updatePool();

        uint256 pending = (entity.shares * accTokenPerShare) /
            PRECISION_FACTOR -
            entity.rewardDebt;

        if (shares > 0) {
            entity.shares -= shares;
            totalShares -= shares;
        }

        if (pending > 0) {
            rewardToken.mint(owner(), pending);
            claim = pending;
            emit Claim(entityId, pending);
        }

        entity.rewardDebt =
            (entity.shares * accTokenPerShare) /
            PRECISION_FACTOR;
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.timestamp <= timestampLast) {
            return;
        }

        if (totalShares == 0) {
            timestampLast = block.timestamp;
            return;
        }
        uint256 rewardWad = (block.timestamp - timestampLast) * rewardPerSecond;
        accTokenPerShare =
            accTokenPerShare +
            ((rewardWad * PRECISION_FACTOR) / totalShares);
        timestampLast = block.timestamp;
        emit Update(accTokenPerShare);
    }

    function getShares(bytes32 _entityId) external view returns (uint256) {
        return entityInfo[_entityId].shares;
    }

    function setRewardPerSecond(uint256 to) external onlyOwner {
        _updatePool();
        rewardPerSecond = to;
        emit SetRPS(rewardPerSecond);
    }

    function setRewardToken(TokenBase to) external onlyOwner {
        rewardToken = to;
        emit SetRewardToken(rewardToken);
    }
}
