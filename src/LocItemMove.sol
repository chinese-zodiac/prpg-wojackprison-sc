// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./LocationBase.sol";
import "./LocWithTokenStore.sol";
import "./PlayerWithStats.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract LocPrepareMove is
    LocationBase,
    PlayerWithStats,
    LocWithTokenStore
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    struct ItemWad {
        ERC20Burnable item;
        uint256 wad;
    }

    mapping(ILocation location => ItemWad itemsRequired)
        public itemsRequiredToMove;
    mapping(ILocation location => ItemWad itemsConsumed)
        public itemsConsumedToMove;

    //travelTime is consumed by a booster
    uint64 public travelTime = 4 hours;
    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME"));

    constructor() {}

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual override(ILocation, LocationBase) {
        ItemWad memory itemWadRequired = itemsRequiredToMove[_to];
        ItemWad memory itemWadConsumed = itemsConsumedToMove[_to];
        if (itemWadRequired.wad > 0 && _entity == player) {
            require(
                entityStoreERC20.getStoredER20WadFor(
                    player,
                    _entityID,
                    itemWadRequired.item
                ) > itemWadRequired.wad,
                "Not enough item to move"
            );
        }
        if (itemWadConsumed.wad > 0 && _entity == player) {
            require(
                entityStoreERC20.getStoredER20WadFor(
                    player,
                    _entityID,
                    itemWadConsumed.item
                ) > itemWadConsumed.wad,
                "Not enough item to move"
            );
            entityStoreERC20.burn(
                player,
                _entityID,
                itemWadConsumed.item,
                itemWadConsumed.wad
            );
        }
    }

    function setItemRequiredDestination(
        ILocation[] calldata _destinations,
        IERC20 item,
        uint256 wad
    ) public onlyRole(VALID_ROUTE_SETTER) {
        setValidDestionation(_destinations, wad > 0);
        for (uint i; i < _destinations.length; i++) {
            itemsRequiredToMove[_destinations[i]].item = ERC20Burnable(
                address(item)
            );
            itemsRequiredToMove[_destinations[i]].wad = wad;
        }
    }

    function setItemConsumedDestination(
        ILocation[] calldata _destinations,
        ERC20Burnable item,
        uint256 wad
    ) public onlyRole(VALID_ROUTE_SETTER) {
        setValidDestionation(_destinations, wad > 0);
        for (uint i; i < _destinations.length; i++) {
            itemsConsumedToMove[_destinations[i]].item = item;
            itemsConsumedToMove[_destinations[i]].wad = wad;
        }
    }
}
