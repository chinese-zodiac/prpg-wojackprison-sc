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
import {Spawner} from "./Spawner.sol";
import {Executor} from "./Executor.sol";
import {Authorizer} from "./Authorizer.sol";
import {EnumerableSetAccessControlViewableUint256} from "./utils/EnumerableSetAccessControlViewableUint256.sol";

contract Entity is
    IEntity,
    Authorizer,
    ModifierOnlySpawner,
    ModifierBlacklisted,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    Spawner internal immutable S;
    Executor internal immutable X;

    Counters.Counter internal _tokenIdTracker;

    EnumerableSetAccessControlViewableUint256 public immutable spawnSet;

    event SetSpawnSet(EnumerableSetAccessControlViewableUint256 set);

    mapping(uint256 id => EntityInfo info) public entityInfo;

    constructor(
        string memory name,
        string memory symbol,
        Executor _executor,
        Spawner _spawner
    ) ERC721(name, symbol) {
        X = _executor;
        S = _spawner;
        spawnSet = new EnumerableSetAccessControlViewableUint256(this);
        emit SetSpawnSet(spawnSet);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function _mint(address _to) internal virtual returns (uint256 id_) {
        ERC721._mint(_to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
        return newTokenId;
    }

    function burn(
        uint256 _nftId
    ) public virtual override(IEntity, ERC721Burnable) blacklisted {
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
