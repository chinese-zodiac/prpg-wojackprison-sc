// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {IBooster} from "../interfaces/IBooster.sol";
import {DatastoreEntityERC721} from "../datastores/DatastoreEntityERC721.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BoosterIERC721Bal is IBooster {
    IERC721 public immutable nft;
    DatastoreEntityERC721 public immutable datastoreEntityERC721;
    //Multiples bps by bal. 10x is 100,000 bps, 100% is 10,000 bps, and 1% is 100 bps.
    uint256 public immutable bps;

    constructor(
        IERC721 _nft,
        DatastoreEntityERC721 _datastoreEntityERC721,
        uint256 _bps
    ) {
        nft = _nft;
        datastoreEntityERC721 = _datastoreEntityERC721;
        bps = _bps;
    }

    function getBoost(
        uint256,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 boost) {
        return (datastoreEntityERC721
            .entityStoredERC721Ids(entity, entityId, nft)
            .getLength() * bps);
    }
}
