// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";

event ActionSuccess(
    ILocation _location,
    address _locCaller,
    IEntity _entity,
    uint256 _entityID,
    bytes32 _aType
);
event ActionSuccess(
    ILocation _location,
    address _locCaller,
    IEntity _entity,
    uint256 _entityID,
    bytes32 _aType,
    address _param
);
event ActionSuccess(
    ILocation _location,
    address _locCaller,
    IEntity _entity,
    uint256 _entityID,
    bytes32 _aType,
    uint256 _param
);
event ActionSuccess(
    ILocation _location,
    address _locCaller,
    IEntity _entity,
    uint256 _entityID,
    bytes32 _aType,
    bytes32 _param
);
event ActionSuccess(
    ILocation _location,
    address _locCaller,
    IEntity _entity,
    uint256 _entityID,
    bytes32 _aType,
    bytes[] _param
);

event SetterSuccess(ILocation _location, bytes32 _sType);
event SetterSuccess(ILocation _location, bytes32 _sType, bool);
event SetterSuccess(ILocation _location, bytes32 _sType, address _param);
event SetterSuccess(ILocation _location, bytes32 _sType, uint256 _param);
event SetterSuccess(ILocation _location, bytes32 _sType, bytes32 _param);
event SetterSuccess(ILocation _location, bytes32 _sType, bytes[] _param);
