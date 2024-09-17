// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;
import {ILocation} from "./ILocation.sol";
import {IEntity} from "./IEntity.sol";
import {IAuthorizer} from "./IAuthorizer.sol";
import {IKey} from "./IKey.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";

interface IAction is IAuthorizer, IKey {
    function metadataIpfsCID() external view returns (string memory cid_);

    function execute(
        address _locCaller,
        ILocation _location,
        IEntity _entity,
        uint256 _entityID,
        bytes calldata _param
    ) external;

    function setMetadata(string calldata to) external;

    function start() external;
    function stop() external;
}
