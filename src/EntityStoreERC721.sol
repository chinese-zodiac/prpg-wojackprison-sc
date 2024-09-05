// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";
import {EnumerableSetAccessControlViewableUint256} from "./utils/EnumerableSetAccessControlViewableUint256.sol";

//Permisionless EntityStoreERC721
//Deposit/withdraw/transfer nfts that are stored to a particular entity
//deposit/withdraw/transfers are restricted to the entity's current location.
contract EntityStoreERC721 {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(IEntity entity => mapping(uint256 entityId => mapping(IERC721 nft => EnumerableSetAccessControlViewableUint256 nftIdSet)))
        public entityStoredERC721Ids;

    ILocationController public immutable locationController;

    error DepositFailed(
        IEntity entity,
        uint256 entityId,
        IERC721 nft,
        uint256 nftId
    );
    error WithdrawFailed(
        IEntity entity,
        uint256 entityId,
        IERC721 nft,
        uint256 nftId
    );
    error TransferFailed(
        IEntity fromEntity,
        uint256 fromEntityId,
        IEntity toEntity,
        uint256 toEntityId,
        IERC721 nft,
        uint256 nftId
    );
    error BurnFailed(
        IEntity entity,
        uint256 entityId,
        IERC721 nft,
        uint256 nftId
    );

    error OnlyEntityLocation(address sender, IEntity entity, uint256 entityId);

    event Deposit(IEntity entity, uint256 entityId, IERC721 nft, uint256 nftId);
    event Withdraw(
        IEntity entity,
        uint256 entityId,
        IERC721 nft,
        uint256 nftId
    );
    event Transfer(
        IEntity fromEntity,
        uint256 fromEntityId,
        IEntity toEntity,
        uint256 toEntityId,
        IERC721 nft,
        uint256 nftId
    );
    event Burn(IEntity entity, uint256 entityId, IERC721 nft, uint256 nftId);

    modifier onlyEntitysLocation(IEntity _entity, uint256 _entityId) {
        if (
            msg.sender !=
            address(locationController.entityIdLocation(_entity, _entityId))
        ) {
            revert OnlyEntityLocation(msg.sender, _entity, _entityId);
        }
        _;
    }

    constructor(ILocationController _locationController) {
        locationController = _locationController;
    }

    function deposit(
        IEntity _entity,
        uint256 _entityId,
        IERC721 _nft,
        uint256[] calldata _nftIds
    ) external onlyEntitysLocation(_entity, _entityId) {
        address location = address(
            locationController.entityIdLocation(_entity, _entityId)
        );
        for (uint i; i < _nftIds.length; i++) {
            _nft.transferFrom(location, address(this), _nftIds[i]);
            entityStoredERC721Ids[_entity][_entityId][_nft].add(_nftIds[i]);
            if (
                !entityStoredERC721Ids[_entity][_entityId][_nft].getContains(
                    _nftIds[i]
                )
            ) {
                revert DepositFailed(_entity, _entityId, _nft, _nftIds[i]);
            }
            emit Deposit(_entity, _entityId, _nft, _nftIds[i]);
        }
    }

    function withdraw(
        IEntity _entity,
        uint256 _entityId,
        IERC721 _nft,
        uint256[] calldata _nftIds
    ) external onlyEntitysLocation(_entity, _entityId) {
        address location = address(
            locationController.entityIdLocation(_entity, _entityId)
        );
        for (uint i; i < _nftIds.length; i++) {
            _nft.transferFrom(address(this), location, _nftIds[i]);
            entityStoredERC721Ids[_entity][_entityId][_nft].remove(_nftIds[i]);
            if (
                entityStoredERC721Ids[_entity][_entityId][_nft].getContains(
                    _nftIds[i]
                )
            ) {
                revert WithdrawFailed(_entity, _entityId, _nft, _nftIds[i]);
            }
            emit Withdraw(_entity, _entityId, _nft, _nftIds[i]);
        }
    }

    function transfer(
        IEntity _fromEntity,
        uint256 _fromEntityId,
        IEntity _toEntity,
        uint256 _toEntityId,
        IERC721 _nft,
        uint256[] calldata _nftIds
    )
        external
        onlyEntitysLocation(_fromEntity, _fromEntityId)
        onlyEntitysLocation(_toEntity, _toEntityId)
    {
        for (uint i; i < _nftIds.length; i++) {
            entityStoredERC721Ids[_fromEntity][_fromEntityId][_nft].remove(
                _nftIds[i]
            );
            entityStoredERC721Ids[_toEntity][_toEntityId][_nft].add(_nftIds[i]);
            if (
                entityStoredERC721Ids[_fromEntity][_fromEntityId][_nft]
                    .getContains(_nftIds[i]) ||
                !entityStoredERC721Ids[_toEntity][_toEntityId][_nft]
                    .getContains(_nftIds[i])
            ) {
                revert TransferFailed(
                    _fromEntity,
                    _fromEntityId,
                    _toEntity,
                    _toEntityId,
                    _nft,
                    _nftIds[i]
                );
            }
            emit Transfer(
                _fromEntity,
                _fromEntityId,
                _toEntity,
                _toEntityId,
                _nft,
                _nftIds[i]
            );
        }
    }

    function burn(
        IEntity _entity,
        uint256 _entityId,
        ERC721Burnable _nft,
        uint256[] calldata _nftIds
    ) external onlyEntitysLocation(_entity, _entityId) {
        for (uint i; i < _nftIds.length; i++) {
            _nft.burn(_nftIds[i]);
            entityStoredERC721Ids[_entity][_entityId][_nft].remove(_nftIds[i]);
            if (
                entityStoredERC721Ids[_entity][_entityId][_nft].getContains(
                    _nftIds[i]
                )
            ) {
                revert BurnFailed(_entity, _entityId, _nft, _nftIds[i]);
            }
            emit Burn(_entity, _entityId, _nft, _nftIds[i]);
        }
    }
}
