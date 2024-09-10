// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Credit to Pancakeswap
pragma solidity ^0.8.19;
import {ILocation} from "./ILocation.sol";
import {IEntity} from "./IEntity.sol";
import {IAuthorizer} from "./IAuthorizer.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";

interface IActionController is IAuthorizer {
    enum PARAM {
        NONE,
        UINT256,
        ADDRESS,
        BYTES32,
        BYTES
    }

    function metadataIpfsCID() external view returns (string memory cid_);
    function AC_KEY() external view returns (bytes32 AC_KEY);

    //aTypes are executable
    function A_TYPE_SET()
        external
        view
        returns (EnumerableSetAccessControlViewableBytes32 aTypeSet_);
    function A_TYPE_ALLOWED_SET()
        external
        view
        returns (EnumerableSetAccessControlViewableBytes32 aTypeRestrictedSet_);
    function aTypeParams(bytes32 _atype) external view returns (PARAM param);

    //sTypes are settable
    function S_TYPE_SET()
        external
        view
        returns (EnumerableSetAccessControlViewableBytes32 sTypeSet_);
    function sTypeParams(bytes32 _atype) external view returns (PARAM param);

    function locationSettingsBool(
        ILocation location,
        bytes32 sType
    ) external view returns (bool);
    function locationSettingsAddress(
        ILocation location,
        bytes32 sType
    ) external view returns (address);
    function locationSettingsUint256(
        ILocation location,
        bytes32 sType
    ) external view returns (uint256);
    function locationSettingsBytes32(
        ILocation location,
        bytes32 sType
    ) external view returns (bytes32);
    function locationSettingsBytes(
        ILocation location,
        bytes32 sType
    ) external view returns (bytes[] memory);

    //events to listen for
    //Events are NOT recursive due to limitations of Solidity.
    //They must only be fired in the execute() method.
    //Not releateed to builtin events
    function LISTEN_SET()
        external
        view
        returns (EnumerableSetAccessControlViewableBytes32 eventSet_);

    function start() external;
    function stop() external;
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType
    ) external returns (bytes32[] memory events_);
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        address _param
    ) external returns (bytes32[] memory events_);
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        uint256 _param
    ) external returns (bytes32[] memory events_);
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        bytes32 _param
    ) external returns (bytes32[] memory events_);
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        bytes[] calldata _param
    ) external returns (bytes32[] memory events_);
    function onEvent(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _event
    ) external;

    function set(ILocation _location, bytes32 _sType) external;
    function set(ILocation _location, bytes32 _sType, address _param) external;
    function set(ILocation _location, bytes32 _sType, uint256 _param) external;
    function set(ILocation _location, bytes32 _sType, bytes32 _param) external;
    function set(
        ILocation _location,
        bytes32 _aType,
        bytes[] calldata _param
    ) external;
}
