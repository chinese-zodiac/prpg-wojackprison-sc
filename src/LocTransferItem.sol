// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessRoleManager} from "./AccessRoleManager.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";
import {LocWithTokenStore} from "./LocWithTokenStore.sol";
import {LocationBase} from "./LocationBase.sol";
import {TokenBase} from "./TokenBase.sol";
import {BoostedValueCalculator} from "./BoostedValueCalculator.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {EntityStoreERC20} from "./EntityStoreERC20.sol";
import {EntityStoreERC721} from "./EntityStoreERC721.sol";
import {ResourceStakingPool} from "./ResourceStakingPool.sol";
import {Counters} from "./libs/Counters.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";

abstract contract LocTransferItem is
    AccessRoleManager,
    LocationBase,
    LocWithTokenStore
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    EnumerableSetAccessControlViewableAddress transferableItemsSet;

    modifier onlyTransferableItem(address item) {
        transferableItemsSet.revertIfNotInSet(item);
        _;
    }

    constructor(
        EnumerableSetAccessControlViewableAddress _transferableItemsSet
    ) {
        transferableItemsSet = _transferableItemsSet;
    }

    function setTransferableItemsSet(
        EnumerableSetAccessControlViewableAddress _transferableItemsSet
    ) external onlyRole(MANAGER_ROLE) {
        transferableItemsSet = _transferableItemsSet;
    }

    function transferIERC20(
        IEntity entity,
        uint256 senderID,
        uint256 receiverID,
        IERC20 token,
        uint256 wad
    )
        external
        onlyEntityOwner(entity, senderID)
        onlyTransferableItem(address(token))
    {
        entityStoreERC20.transfer(
            entity,
            senderID,
            entity,
            receiverID,
            token,
            wad
        );
    }

    function transferIERC721(
        IEntity entity,
        uint256 senderID,
        uint256 receiverID,
        IERC721 token,
        uint256[] calldata ids
    )
        external
        onlyEntityOwner(entity, senderID)
        onlyTransferableItem(address(token))
    {
        entityStoreERC721.transfer(
            entity,
            senderID,
            entity,
            receiverID,
            token,
            ids
        );
    }
}
