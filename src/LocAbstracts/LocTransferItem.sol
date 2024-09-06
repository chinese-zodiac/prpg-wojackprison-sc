// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {LocBase} from "./LocBase.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract LocTransferItem is LocBase {
    modifier onlyTransferableItem(address item) {
        regionSettings.transferableItemsSet().revertIfNotInSet(item);
        _;
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
        regionSettings.entityStoreERC20().transfer(
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
        regionSettings.entityStoreERC721().transfer(
            entity,
            senderID,
            entity,
            receiverID,
            token,
            ids
        );
    }
}
