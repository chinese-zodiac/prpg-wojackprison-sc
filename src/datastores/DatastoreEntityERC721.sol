// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {DatastoreEntityLocation} from "./DatastoreEntityLocation.sol";
import {EACSetUint256} from "../utils/EACSetUint256.sol";
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {DatastoreBase} from "./DatastoreBase.sol";

//Permisionless EntityStoreERC721
//Deposit/withdraw/transfer nfts that are stored to a particular entity
//deposit/withdraw/transfers are restricted to the entity's current location.
contract DatastoreEntityERC721 is DatastoreBase {
    bytes32 public constant KEY = keccak256("DATASTORE_ENTITY_ERC721");
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(IEntity entity => mapping(uint256 entityId => mapping(IERC721 nft => EACSetUint256 nftIdSet)))
        public entityStoredERC721Ids;

    mapping(IERC721 entity => mapping(uint256 entityId => EACSetAddress tokens))
        public entityStoredTokens;

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

    constructor(IExecutor _executor) DatastoreBase(_executor) {}

    function deposit(
        IEntity _entity,
        uint256 _entityId,
        IERC721 _nft,
        uint256[] calldata _nftIds
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        updateSets(_entity, _entityId, _nft);
        for (uint i; i < _nftIds.length; i++) {
            _nft.transferFrom(msg.sender, address(this), _nftIds[i]);
            entityStoredERC721Ids[_entity][_entityId][_nft].add(_nftIds[i]);
            emit Deposit(_entity, _entityId, _nft, _nftIds[i]);
        }
    }

    function withdraw(
        IEntity _entity,
        uint256 _entityId,
        IERC721 _nft,
        uint256[] calldata _nftIds,
        address _receiver
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        for (uint i; i < _nftIds.length; i++) {
            _nft.transferFrom(address(this), _receiver, _nftIds[i]);
            entityStoredERC721Ids[_entity][_entityId][_nft].remove(_nftIds[i]);
            emit Withdraw(_entity, _entityId, _nft, _nftIds[i]);
        }
        deleteEntityUnusedTokens(_entity, _entityId, _nft);
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
        onlyExecutor(X)
        blacklistedEntity(X, _fromEntity, _fromEntityId)
        blacklistedEntity(X, _toEntity, _toEntityId)
    {
        DatastoreEntityLocation dsELoc = DatastoreEntityLocation(
            X.globalSettings().registries(DATASTORE_ENTITY_LOCATION)
        );
        dsELoc.revertIfEntityNotAtLocation(
            _toEntity,
            _toEntityId,
            dsELoc.entityLocation(_fromEntity, _fromEntityId)
        );
        updateSets(_toEntity, _toEntityId, _nft);
        for (uint i; i < _nftIds.length; i++) {
            entityStoredERC721Ids[_fromEntity][_fromEntityId][_nft].remove(
                _nftIds[i]
            );
            entityStoredERC721Ids[_toEntity][_toEntityId][_nft].add(_nftIds[i]);
            emit Transfer(
                _fromEntity,
                _fromEntityId,
                _toEntity,
                _toEntityId,
                _nft,
                _nftIds[i]
            );
        }
        deleteEntityUnusedTokens(_fromEntity, _fromEntityId, _nft);
    }

    function burn(
        IEntity _entity,
        uint256 _entityId,
        ERC721Burnable _nft,
        uint256[] calldata _nftIds
    ) external onlyExecutor(X) blacklistedEntity(X, _entity, _entityId) {
        for (uint i; i < _nftIds.length; i++) {
            _nft.burn(_nftIds[i]);
            entityStoredERC721Ids[_entity][_entityId][_nft].remove(_nftIds[i]);
            emit Burn(_entity, _entityId, _nft, _nftIds[i]);
        }
        deleteEntityUnusedTokens(_entity, _entityId, _nft);
    }

    function updateSets(
        IEntity _entity,
        uint256 _entityId,
        IERC721 _nft
    ) public {
        if (
            address(entityStoredERC721Ids[_entity][_entityId][_nft]) ==
            address(0x0)
        ) {
            entityStoredERC721Ids[_entity][_entityId][
                _nft
            ] = new EACSetUint256();
        }
        if (address(entityStoredTokens[_entity][_entityId]) == address(0x0)) {
            entityStoredTokens[_entity][_entityId] = new EACSetAddress();
        }
        if (
            !entityStoredTokens[_entity][_entityId].getContains(address(_nft))
        ) {
            entityStoredTokens[_entity][_entityId].add(address(_nft));
        }
    }

    function deleteEntityUnusedTokens(
        IEntity _entity,
        uint256 _entityId,
        IERC721 _nft
    ) public {
        if (entityStoredERC721Ids[_entity][_entityId][_nft].getLength() == 0) {
            entityStoredTokens[_entity][_entityId].remove(address(_nft));
        }
    }

    //Escape hatch for emergency use
    function recoverERC721(
        IERC721 _nft,
        uint256[] calldata _nftIds
    ) external onlyAdmin {
        for (uint i; i < _nftIds.length; i++) {
            _nft.transferFrom(address(this), msg.sender, _nftIds[i]);
        }
    }
}
