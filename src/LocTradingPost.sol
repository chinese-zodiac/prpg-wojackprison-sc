// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./AccessRoleManager.sol";
import "./LocTransferItem.sol";
import "./TokenBase.sol";
import "./BoostedValueCalculator.sol";
import "./interfaces/IEntity.sol";
import "./EntityStoreERC20.sol";
import "./ResourceStakingPool.sol";
import "./libs/Counters.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LocTradingPost is AccessRoleManager, LocTransferItem {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    struct ShopItem {
        TokenBase item;
        TokenBase currency;
        uint256 pricePerItemWad;
        uint256 increasePerItemSold;
        uint256 totalSold;
    }

    address public taxReceiver;
    uint256 public taxBPS = 0;

    EnumerableSet.UintSet shopItemKeys;
    Counters.Counter shopItemNextUid;
    mapping(uint256 => ShopItem) public shopItems;

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
    event SetTaxReceiver(address taxReceiver);
    event SetTaxBPS(uint256 taxBPS);

    constructor(
        ILocationController _locationController,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721,
        address _taxReceiver,
        uint256 _taxBPS
    )
        LocTransferItem(
            _locationController,
            _entityStoreERC20,
            _entityStoreERC721
        )
    {
        taxReceiver = _taxReceiver;
        taxBPS = _taxBPS;
        emit SetTaxReceiver(taxReceiver);
        emit SetTaxBPS(taxBPS);
    }

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
        uint256 taxFee = (totalFee * taxBPS) / 10_000;
        emit BuyShopItem(
            entity,
            entityId,
            shopItemId,
            quantity,
            taxFee,
            totalFee
        );
        if (taxFee > 0) {
            entityStoreERC20.withdraw(
                entity,
                entityId,
                item.currency,
                totalFee - taxFee
            );
            item.currency.transfer(
                taxReceiver,
                item.currency.balanceOf(address(this))
            );
        }
        entityStoreERC20.burn(
            entity,
            entityId,
            item.currency,
            totalFee - taxFee
        );
        item.item.mint(address(this), quantity);
        item.totalSold += quantity;
        item.item.approve(address(entityStoreERC20), quantity);
        entityStoreERC20.deposit(entity, entityId, item.item, quantity);
    }

    //High gas usage, view only
    function viewOnly_getAllShopItems()
        external
        view
        returns (ShopItem[] memory items)
    {
        items = new ShopItem[](shopItemKeys.length());
        for (uint i; i < shopItemKeys.length(); i++) {
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
        require(shopItemKeys.length() > index, "index not in shop");
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
        require(shopItemKeys.length() > index, "index not in shop");
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

    function setTaxReceiver(address _to) external onlyManager {
        taxReceiver = _to;
        emit SetTaxReceiver(taxReceiver);
    }

    function setTaxBPS(uint256 _to) external onlyManager {
        require(_to <= 10_000, "Cannot be more than 10,000 BPS (100%)");
        taxBPS = _to;
        emit SetTaxBPS(taxBPS);
    }
}
