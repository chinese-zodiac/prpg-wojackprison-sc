// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {LocBase} from "./LocBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract LocSpendItemToMove is LocBase {
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

    error InvalidDestination(ILocation destination);

    event SetItemConsumedDestination(
        ILocation destination,
        ERC20Burnable item,
        uint256 consumedWad
    );

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual override {
        ItemWad memory item = items[_to];
        IEntity player = regionSettings.player();
        if (item.consumedWad > 0 && _entity == player) {
            uint256 balanceWad = regionSettings
                .entityStoreERC20()
                .getStoredER20WadFor(player, _entityID, item.item);
            if (balanceWad < item.consumedWad) {
                revert NotEnoughItem(
                    item.item,
                    item.consumedWad,
                    item.consumedWad
                );
            }
            regionSettings.entityStoreERC20().burn(
                player,
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
    ) public onlyManager {
        for (uint i; i < _destinations.length; i++) {
            ILocation dest = _destinations[i];
            if (
                _consumedWad > 0 &&
                !validDestinationSet.getContains(address(dest))
            ) {
                revert InvalidDestination(_destinations[i]);
            }
            items[dest].item = _item;
            items[dest].consumedWad = _consumedWad;
            emit SetItemConsumedDestination(dest, _item, _consumedWad);
        }
    }
}
