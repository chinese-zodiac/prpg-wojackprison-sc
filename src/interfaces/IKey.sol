// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IKey {
    function KEY() external view returns (bytes32 key);
}
