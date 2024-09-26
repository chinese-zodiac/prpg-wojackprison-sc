// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.23;
import {IEntity} from "./IEntity.sol";
import {IKey} from "./IKey.sol";
import {EACSetBytes32} from "../utils/EACSetBytes32.sol";

interface IAction is IKey {
    function metadataIpfsCID() external view returns (string memory cid_);

    function execute(
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes calldata _param
    ) external returns (address[] memory callees, bytes[] memory encodedCalls);

    function setMetadata(string calldata to) external;

    function start() external;
    function stop() external;
}
