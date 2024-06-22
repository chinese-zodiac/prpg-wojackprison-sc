// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICZUSD is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}
