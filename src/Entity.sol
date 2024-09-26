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
import {ModifierBlacklisted} from "./utils/ModifierBlacklisted.sol";
import {ModifierOnlySpawner} from "./utils/ModifierOnlySpawner.sol";
import {ISpawner} from "./interfaces/ISpawner.sol";
import {IExecutor} from "./interfaces/IExecutor.sol";
import {EACSetUint256} from "./utils/EACSetUint256.sol";

contract Entity is
    IEntity,
    AccessControlEnumerable,
    ModifierOnlySpawner,
    ModifierBlacklisted,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    ISpawner internal immutable S;
    IExecutor internal immutable X;

    Counters.Counter internal _tokenIdTracker;

    EACSetUint256 public immutable spawnSet;

    event SetSpawnSet(EACSetUint256 set);

    constructor(
        string memory name,
        string memory symbol,
        IExecutor _executor,
        ISpawner _spawner
    ) ERC721(name, symbol) {
        X = _executor;
        S = _spawner;
        spawnSet = new EACSetUint256();
        emit SetSpawnSet(spawnSet);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _mint(address _to) internal virtual returns (uint256 id_) {
        id_ = _tokenIdTracker.current();
        ERC721._mint(_to, id_);
        _tokenIdTracker.increment();
    }

    function burn(
        uint256 _nftId
    ) public virtual override(IEntity, ERC721Burnable) {
        ERC721Burnable.burn(_nftId);
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
    )
        internal
        override(ERC721, ERC721Enumerable)
        blacklisted(X, msg.sender)
        blacklistedEntity(X, this, tokenId)
        returns (address)
    {
        return ERC721Enumerable._update(to, tokenId, auth);
    }

    function mint(
        address _receiver
    )
        external
        onlySpawner(S)
        blacklisted(X, _receiver)
        returns (uint256 nftId)
    {
        return _mint(_receiver);
    }
}
