// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {EnumerableSetAccessControlViewableUint256} from "../utils/EnumerableSetAccessControlViewableUint256.sol";

interface IEntity is IERC721Enumerable {
    function burn(uint256 tokenId) external;
    function spawnSet()
        external
        view
        returns (EnumerableSetAccessControlViewableUint256 set);
    function mint(
        address _receiver,
        bytes32 _eType,
        bytes32 _randWord
    ) external returns (uint256 nftId);
}
