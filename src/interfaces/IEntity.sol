// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {EACSetUint256} from "../utils/EACSetUint256.sol";

interface IEntity is IERC721Enumerable {
    function burn(uint256 tokenId) external;
    function spawnSet() external view returns (EACSetUint256 set);
    function mint(address _receiver) external returns (uint256 nftId);
}
