// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {LocationBase} from "./LocationBase.sol";
import {LocWithTokenStore} from "./LocWithTokenStore.sol";
import {LocPlayerWithStats} from "./LocPlayerWithStats.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract LocSpendItemToMove is
    LocationBase,
    LocPlayerWithStats,
    LocWithTokenStore
{
    struct ItemWad {
        ERC20Burnable item;
        uint256 consumedWad;
    }

    mapping(ILocation location => ItemWad itemsConsumed) public items;

    error NotEnoughItem(
        ERC20Burnable item,
        uint256 consumedWad,
        uint256 balanceWad
    );

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual override(ILocation, LocationBase) {
        ItemWad memory item = items[_to];
        if (item.consumedWad > 0 && _entity == PLAYER) {
            uint256 balanceWad = entityStoreERC20.getStoredER20WadFor(
                PLAYER,
                _entityID,
                item.item
            );
            if (balanceWad < item.consumedWad) {
                revert NotEnoughItem(
                    item.item,
                    item.consumedWad,
                    item.consumedWad
                );
            }
            entityStoreERC20.burn(
                PLAYER,
                _entityID,
                item.item,
                item.consumedWad
            );
        }
    }

    function setItemConsumedDestination(
        ILocation[] calldata _destinations,
        ERC20Burnable _item,
        uint256 _consumedWad
    ) public {
        if (
            !validDestinationSet.hasRole(
                validDestinationSet.MANAGER_ROLE(),
                msg.sender
            )
        ) {
            revert AccessControlUnauthorizedAccount(
                msg.sender,
                validDestinationSet.MANAGER_ROLE()
            );
        }
        for (uint i; i < _destinations.length; i++) {
            if (
                _consumedWad > 0 &&
                !validDestinationSet.getContains(address(_destinations[i]))
            ) {
                validDestinationSet.add(address(_destinations[i]));
            }
            items[_destinations[i]].item = _item;
            items[_destinations[i]].consumedWad = _consumedWad;
        }
    }
}
