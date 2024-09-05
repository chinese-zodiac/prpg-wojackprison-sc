// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IBooster} from "./interfaces/IBooster.sol";
import {EntityStoreERC721} from "./EntityStoreERC721.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BoosterIERC721Bal is IBooster {
    IERC721 public immutable nft;
    EntityStoreERC721 public immutable entityStoreERC721;
    //Multiples bps by bal. 10x is 100,000 bps, 100% is 10,000 bps, and 1% is 100 bps.
    uint256 public immutable bps;

    constructor(
        IERC721 _nft,
        EntityStoreERC721 _entityStoreERC20,
        uint256 _bps
    ) {
        nft = _nft;
        entityStoreERC721 = _entityStoreERC20;
        bps = _bps;
    }

    function getBoost(
        ILocation,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 boost) {
        return (entityStoreERC721
            .entityStoredERC721Ids(entity, entityId, nft)
            .getLength() * bps);
    }
}
