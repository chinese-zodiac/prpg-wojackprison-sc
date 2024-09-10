// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IActionController} from "../interfaces/IActionController.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {IAuthorizer} from "../interfaces/IAuthorizer.sol";
import {Authorizer} from "../Authorizer.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import "./ACEvents.sol" as ACEvents;
import {ACRevertsLib} from "./ACRevertsLib.sol";

contract ActionController is IActionController, Authorizer {
    string public metadataIpfsCID;
    //Action types
    EnumerableSetAccessControlViewableBytes32 public immutable A_TYPE_SET;
    //Setter types, for managers
    EnumerableSetAccessControlViewableBytes32 public immutable S_TYPE_SET;
    //Events the ActionController listens for
    EnumerableSetAccessControlViewableBytes32 public immutable LISTEN_SET;
    mapping(bytes32 aType => PARAM param) public aTypeParams;
    mapping(bytes32 sType => PARAM param) public sTypeParams;
    //If length > 0, only actions in this set allowed
    //TODOFIX: Currently locks for all entities/locations
    //Should instead have granular locks
    EnumerableSetAccessControlViewableBytes32
        public immutable A_TYPE_ALLOWED_SET;

    mapping(ILocation location => mapping(bytes32 sType => bool))
        public locationSettingsBool;
    mapping(ILocation location => mapping(bytes32 sType => address))
        public locationSettingsAddress;
    mapping(ILocation location => mapping(bytes32 sType => uint256))
        public locationSettingsUint256;
    mapping(ILocation location => mapping(bytes32 sType => bytes32))
        public locationSettingsBytes32;
    mapping(ILocation location => mapping(bytes32 sType => bytes[]))
        internal _locationSettingsBytes;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        //For the A_TYPE_SET, S_TYPE_SET, and LISTEN_SET, these should only be modified by (this).
        _grantRole(MANAGER_ROLE, address(this));
        A_TYPE_SET = new EnumerableSetAccessControlViewableBytes32(
            IAuthorizer(this)
        );
        A_TYPE_ALLOWED_SET = new EnumerableSetAccessControlViewableBytes32(
            IAuthorizer(this)
        );
        S_TYPE_SET = new EnumerableSetAccessControlViewableBytes32(
            IAuthorizer(this)
        );
        LISTEN_SET = new EnumerableSetAccessControlViewableBytes32(
            IAuthorizer(this)
        );
    }

    function start() public virtual {}
    function stop() public virtual {}

    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType
    ) public virtual returns (bytes32[] memory events_) {
        ACRevertsLib.revertActionDefaults(
            A_TYPE_SET,
            aTypeParams,
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType,
            PARAM.NONE
        );
    }
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        address
    ) public virtual returns (bytes32[] memory events_) {
        ACRevertsLib.revertActionDefaults(
            A_TYPE_SET,
            aTypeParams,
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType,
            PARAM.ADDRESS
        );
    }
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        uint256
    ) public virtual returns (bytes32[] memory events_) {
        ACRevertsLib.revertActionDefaults(
            A_TYPE_SET,
            aTypeParams,
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType,
            PARAM.UINT256
        );
    }
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        bytes32
    ) public virtual returns (bytes32[] memory events_) {
        ACRevertsLib.revertActionDefaults(
            A_TYPE_SET,
            aTypeParams,
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType,
            PARAM.BYTES32
        );
    }
    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        bytes[] calldata //_param
    ) public virtual returns (bytes32[] memory events_) {
        ACRevertsLib.revertActionDefaults(
            A_TYPE_SET,
            aTypeParams,
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType,
            PARAM.BYTES
        );
    }
    function onEvent(
        ILocation _location,
        address, // _locCaller,
        IEntity, // _entity,
        uint256, // _entityID,
        bytes32 // _event
    ) public virtual {
        ACRevertsLib.revertIfSenderNotLocation(_location);
    }
    function set(ILocation _location, bytes32 _sType) external {
        ACRevertsLib.revertSetterDefaults(
            S_TYPE_SET,
            sTypeParams,
            _location,
            _sType,
            PARAM.NONE
        );
        locationSettingsBool[_location][_sType] = !locationSettingsBool[
            _location
        ][_sType];
        emit ACEvents.SetterSuccess(
            _location,
            _sType,
            locationSettingsBool[_location][_sType]
        );
    }
    function set(ILocation _location, bytes32 _sType, address _param) external {
        ACRevertsLib.revertSetterDefaults(
            S_TYPE_SET,
            sTypeParams,
            _location,
            _sType,
            PARAM.ADDRESS
        );
        locationSettingsAddress[_location][_sType] = _param;
        emit ACEvents.SetterSuccess(_location, _sType, _param);
    }
    function set(ILocation _location, bytes32 _sType, uint256 _param) external {
        ACRevertsLib.revertSetterDefaults(
            S_TYPE_SET,
            sTypeParams,
            _location,
            _sType,
            PARAM.UINT256
        );
        locationSettingsUint256[_location][_sType] = _param;
        emit ACEvents.SetterSuccess(_location, _sType, _param);
    }
    function set(ILocation _location, bytes32 _sType, bytes32 _param) external {
        ACRevertsLib.revertSetterDefaults(
            S_TYPE_SET,
            sTypeParams,
            _location,
            _sType,
            PARAM.BYTES32
        );
        locationSettingsBytes32[_location][_sType] = _param;
        emit ACEvents.SetterSuccess(_location, _sType, _param);
    }
    function set(
        ILocation _location,
        bytes32 _sType,
        bytes[] calldata _param
    ) external {
        ACRevertsLib.revertSetterDefaults(
            S_TYPE_SET,
            sTypeParams,
            _location,
            _sType,
            PARAM.BYTES
        );
        _locationSettingsBytes[_location][_sType] = _param;
        emit ACEvents.SetterSuccess(_location, _sType, _param);
    }

    function locationSettingsBytes(
        ILocation _location,
        bytes32 _sType
    ) external view returns (bytes[] memory data) {
        return _locationSettingsBytes[_location][_sType];
    }

    function setMetadata(string calldata to) external onlyAdmin {
        metadataIpfsCID = to;
    }

    function AC_KEY() external view virtual returns (bytes32 acKey) {
        return bytes32(0x0);
    }
}
