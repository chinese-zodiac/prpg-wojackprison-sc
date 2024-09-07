// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {LocBase} from "../LocAbstracts/LocBase.sol";
import {LocTransferItem} from "../LocAbstracts/LocTransferItem.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {HasRegionSettings} from "../utils/HasRegionSettings.sol";
import {TokenBase} from "../TokenBase.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {Counters} from "../libs/Counters.sol";
import {EntityStoreERC20} from "../EntityStoreERC20.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LocationTradingPost is LocBase, LocTransferItem {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    struct ShopItem {
        TokenBase item;
        TokenBase currency;
        uint256 pricePerItemWad;
        uint256 increasePerItemSold;
        uint256 totalSold;
    }

    EnumerableSet.UintSet internal shopItemKeys;
    Counters.Counter internal shopItemNextUid;
    mapping(uint256 itemId => ShopItem item) public shopItems;

    event SetItemInShop(
        uint256 id,
        TokenBase item,
        TokenBase currency,
        uint256 pricePerItemWad,
        uint256 increasePerItemSold
    );
    event DeleteItemFromShop(uint256 id);
    event BuyShopItem(
        IEntity entity,
        uint256 entityId,
        uint256 shopItemId,
        uint256 quantity,
        uint256 taxFee,
        uint256 totalFee
    );

    error IndexNotInShop(uint256 index);

    constructor(
        RegionSettings _regionSettings,
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet
    )
        HasRegionSettings(_regionSettings)
        LocBase(_validSourceSet, _validDestinationSet)
    {}

    function buyShopItem(
        IEntity entity,
        uint256 entityId,
        uint256 shopItemId,
        uint256 quantity
    )
        external
        onlyLocalEntity(entity, entityId)
        onlyEntityOwner(entity, entityId)
    {
        ShopItem memory item = shopItems[shopItemId];
        uint256 totalFee = (quantity *
            (item.pricePerItemWad +
                item.totalSold *
                item.increasePerItemSold)) / 1 ether;
        uint256 taxFee = (totalFee * regionSettings.taxBps()) / 10_000;
        emit BuyShopItem(
            entity,
            entityId,
            shopItemId,
            quantity,
            taxFee,
            totalFee
        );
        EntityStoreERC20 erc20Store = regionSettings.entityStoreERC20();
        if (taxFee > 0) {
            erc20Store.withdraw(
                entity,
                entityId,
                item.currency,
                totalFee - taxFee
            );
            item.currency.transfer(
                regionSettings.taxReceiver(),
                item.currency.balanceOf(address(this))
            );
        }
        erc20Store.burn(entity, entityId, item.currency, totalFee - taxFee);
        item.item.mint(address(this), quantity);
        item.totalSold += quantity;
        item.item.approve(address(erc20Store), quantity);
        erc20Store.deposit(entity, entityId, item.item, quantity);
    }

    //High gas usage, view only
    function viewOnly_getAllShopItems()
        external
        view
        returns (ShopItem[] memory items)
    {
        items = new ShopItem[](shopItemKeys.length());
        for (uint256 i; i < shopItemKeys.length(); i++) {
            items[i] = (shopItems[shopItemKeys.at(i)]);
        }
    }

    function getShopItemsCount() public view returns (uint256) {
        return shopItemKeys.length();
    }

    function getShopItemAt(
        uint256 index
    ) public view returns (ShopItem memory) {
        return shopItems[shopItemKeys.at(index)];
    }

    function addItemToShop(
        TokenBase item,
        TokenBase currency,
        uint256 pricePerItemWad,
        uint256 increasePerItemSold
    ) external onlyManager {
        uint256 id = shopItemNextUid.current();
        emit SetItemInShop(
            id,
            item,
            currency,
            pricePerItemWad,
            increasePerItemSold
        );
        shopItemKeys.add(id);
        shopItems[id].item = item;
        shopItems[id].currency = currency;
        shopItems[id].pricePerItemWad = pricePerItemWad;
        shopItems[id].increasePerItemSold = increasePerItemSold;
        shopItemNextUid.increment();
    }

    function setItemInShop(
        uint256 index,
        TokenBase item,
        TokenBase currency,
        uint256 pricePerItemWad,
        uint256 increasePerItemSold
    ) external onlyManager {
        if (shopItemKeys.length() <= index) {
            revert IndexNotInShop(index);
        }
        uint256 id = shopItemKeys.at(index);
        emit SetItemInShop(
            id,
            item,
            currency,
            pricePerItemWad,
            increasePerItemSold
        );
        shopItems[id].item = item;
        shopItems[id].currency = currency;
        shopItems[id].pricePerItemWad = pricePerItemWad;
        shopItems[id].increasePerItemSold = increasePerItemSold;
    }

    function deleteItemFromShop(uint256 index) external onlyManager {
        if (shopItemKeys.length() <= index) {
            revert IndexNotInShop(index);
        }
        uint256 id = shopItemKeys.at(index);
        emit DeleteItemFromShop(id);
        delete shopItems[id].item;
        delete shopItems[id].currency;
        delete shopItems[id].pricePerItemWad;
        delete shopItems[id].increasePerItemSold;
        delete shopItems[id].totalSold;
        delete shopItems[id];
        shopItemKeys.remove(id);
    }
}
