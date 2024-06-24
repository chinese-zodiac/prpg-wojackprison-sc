// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./LocationBase.sol";
import "./TokenBase.sol";
import "./BoostedValueCalculator.sol";
import "./interfaces/IEntity.sol";
import "./EntityStoreERC20.sol";
import "./EntityStoreERC721.sol";
import "./ResourceStakingPool.sol";
import "./libs/Counters.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LocTransferItem is LocationBase {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    EntityStoreERC20 public entityStoreERC20;
    EntityStoreERC721 public entityStoreERC721;

    EnumerableSet.AddressSet transferableItems;

    modifier onlyEntityOwner(IEntity entity, uint256 entityId) {
        require(msg.sender == entity.ownerOf(entityId), "Only entity owner");
        _;
    }

    modifier onlyTransferableItem(address item) {
        require(transferableItems.contains(item));
        _;
    }

    constructor(
        ILocationController _locationController,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721
    ) LocationBase(_locationController) {
        entityStoreERC20 = _entityStoreERC20;
        entityStoreERC721 = _entityStoreERC721;
    }

    function transferIERC20(
        IEntity entity,
        uint256 senderID,
        uint256 receiverID,
        IERC20 token,
        uint256 wad
    )
        external
        onlyLocalEntity(entity, senderID)
        onlyLocalEntity(entity, receiverID)
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
        onlyLocalEntity(entity, senderID)
        onlyLocalEntity(entity, receiverID)
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

    //High gas usage, view only
    function viewOnly_getAllTransferableItems()
        external
        view
        returns (address[] memory items)
    {
        items = new address[](transferableItems.length());
        for (uint i; i < transferableItems.length(); i++) {
            items[i] = transferableItems.at(i);
        }
    }

    function getTransferableItemsCount() public view returns (uint256) {
        return transferableItems.length();
    }

    function getTransferableItemAt(
        uint256 index
    ) public view returns (address) {
        return transferableItems.at(index);
    }

    function addTransferableItem(address item) external onlyRole(MANAGER_ROLE) {
        transferableItems.add(item);
    }

    function deleteTransferableItem(
        address item
    ) external onlyRole(MANAGER_ROLE) {
        transferableItems.remove(item);
    }
}
