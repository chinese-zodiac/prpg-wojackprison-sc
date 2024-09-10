// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {IActionController} from "../interfaces/IActionController.sol";

error LocCallerNotEntityOwner(
    address locCaller,
    IEntity entity,
    uint256 entityID
);
error SenderNotLocation(address sender, ILocation location);
error ParamNotImplemented(IActionController.PARAM paramType);
error InvalidParamType(
    bytes32 aOrSType,
    IActionController.PARAM expectedParam,
    IActionController.PARAM actualParam
);
error InvalidAType(bytes32 aType);
error InvalidSType(bytes32 aType);
error NotAllowedAType(bytes32 aType);
