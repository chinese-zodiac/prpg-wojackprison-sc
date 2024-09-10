// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {ACMove} from "./move/ACMove.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {IActionController} from "../interfaces/IActionController.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import "./ACErrors.sol" as ACErrors;

library ACRevertsLib {
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    function revertActionDefaults(
        EnumerableSetAccessControlViewableBytes32 aTypeSet,
        mapping(bytes32 aType => IActionController.PARAM param)
            storage aTypeParams,
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        IActionController.PARAM _expectedParamType
    ) internal view {
        revertIfInvalidParamType(
            _aType,
            aTypeParams[_aType],
            _expectedParamType
        );
        revertIfInvalidAType(aTypeSet, _aType);
        revertIfSenderNotLocation(_location);
        revertIfLocCallerNotEntityOwner(_locCaller, _entity, _entityID);
    }

    function revertSetterDefaults(
        EnumerableSetAccessControlViewableBytes32 sTypeSet,
        mapping(bytes32 sType => IActionController.PARAM param)
            storage sTypeParams,
        ILocation _location,
        bytes32 _sType,
        IActionController.PARAM _expectedParamType
    ) internal view {
        revertIfInvalidParamType(
            _sType,
            sTypeParams[_sType],
            _expectedParamType
        );
        revertIfInvalidSType(sTypeSet, _sType);
        revertIfSenderNotManagerOnLocation(_location);
    }

    function revertIfSenderNotManagerOnLocation(
        ILocation location
    ) internal view {
        location.revertIfNotAuthorized(MANAGER_ROLE, msg.sender);
    }

    function revertIfInvalidSType(
        EnumerableSetAccessControlViewableBytes32 sTypeSet,
        bytes32 _sType
    ) internal view {
        if (!sTypeSet.getContains(_sType)) {
            revert ACErrors.InvalidSType(_sType);
        }
    }

    function revertIfInvalidAType(
        EnumerableSetAccessControlViewableBytes32 aTypeSet,
        bytes32 _aType
    ) internal view {
        if (!aTypeSet.getContains(_aType)) {
            revert ACErrors.InvalidAType(_aType);
        }
    }

    function revertIfNotAllowedAType(
        EnumerableSetAccessControlViewableBytes32 aTypeSet,
        bytes32 _aType
    ) internal view {
        if (!aTypeSet.getContains(_aType)) {
            revert ACErrors.NotAllowedAType(_aType);
        }
    }

    function revertIfLocCallerNotEntityOwner(
        address _locCaller,
        IEntity _entity,
        uint256 _entityID
    ) internal view {
        if (_entity.ownerOf(_entityID) != _locCaller) {
            revert ACErrors.LocCallerNotEntityOwner(
                _locCaller,
                _entity,
                _entityID
            );
        }
    }

    function revertIfInvalidParamType(
        bytes32 aType,
        IActionController.PARAM expectedParam,
        IActionController.PARAM actualParam
    ) internal pure {
        if (expectedParam != actualParam) {
            revert ACErrors.InvalidParamType(aType, expectedParam, actualParam);
        }
    }

    function revertIfSenderNotLocation(ILocation _location) internal view {
        if (msg.sender != address(_location)) {
            revert ACErrors.SenderNotLocation(msg.sender, _location);
        }
    }
}
