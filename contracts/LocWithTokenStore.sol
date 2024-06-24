// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "./EntityStoreERC20.sol";
import "./EntityStoreERC721.sol";

contract LocWithTokenStore {
    EntityStoreERC20 public immutable entityStoreERC20;
    EntityStoreERC721 public immutable entityStoreERC721;

    constructor(
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721
    ) {
        entityStoreERC20 = _entityStoreERC20;
        entityStoreERC721 = _entityStoreERC721;
    }
}
