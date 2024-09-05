// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import {Counters} from "./libs/Counters.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";

contract Entity is
    IEntity,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    ILocationController public locationController;

    struct EntityInfo {
        bytes32 seed; //Random seed used to determine nft stats on 3rd contracts
        bytes32 eType; //Used for nfts with different types, for instance beta/free/paid
    }

    mapping(uint256 id => EntityInfo info) public entityInfo;

    constructor(
        string memory name,
        string memory symbol,
        ILocationController _locationController
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        locationController = _locationController;
    }

    function _mint(
        address _to,
        ILocation _location,
        bytes32 _eType,
        bytes32 _randWord
    ) internal virtual returns (uint256 id_) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "JNT: must have manager role to mint"
        );

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 newTokenId = _tokenIdTracker.current();
        _mint(address(this), newTokenId);

        locationController.spawn(this, newTokenId, _location);

        EntityInfo storage info = entityInfo[newTokenId];

        info.seed = _randWord;
        info.eType = _eType;

        _transfer(address(this), _to, newTokenId);

        _tokenIdTracker.increment();

        return newTokenId;
    }

    function burn(
        uint256 _nftId
    ) public virtual override(IEntity, ERC721Burnable) {
        locationController.despawn(this, _nftId);
        ERC721Burnable.burn(_nftId);
    }

    function seed(uint256 _nftId) external view returns (bytes32 _seed) {
        _seed = entityInfo[_nftId].seed;
    }

    function eType(uint256 _nftId) external view returns (bytes32 _eType) {
        _eType = entityInfo[_nftId].eType;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721Enumerable, ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _increaseBalance(
        address account,
        uint128 amount
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, amount);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return ERC721Enumerable._update(to, tokenId, auth);
    }
}
