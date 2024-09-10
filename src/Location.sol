// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {ILocation} from "./interfaces/ILocation.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {IActionController} from "./interfaces/IActionController.sol";
import {IAuthorizer} from "./interfaces/IAuthorizer.sol";
import {Authorizer} from "./Authorizer.sol";
import {RegionSettings} from "./RegionSettings.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";

contract Location is Authorizer, ILocation {
    EnumerableSetAccessControlViewableAddress public acSet;
    RegionSettings public regionSettings;

    event SetRegionSettings(RegionSettings regionSettings);

    event ExecuteAction(
        ILocation location,
        address sender,
        IEntity entity,
        uint256 entityID,
        bytes32 aType
    );
    event SetActionSet(EnumerableSetAccessControlViewableAddress acSet);

    error InvalidAction(IActionController ac);
    error InvalidActionParam(
        IActionController ac,
        bytes32 aType,
        IActionController.PARAM expectedParam,
        IActionController.PARAM actualParam
    );

    constructor(address _manager, RegionSettings _regionSettings) {
        regionSettings = _regionSettings;
        emit SetRegionSettings(regionSettings);

        acSet = new EnumerableSetAccessControlViewableAddress(
            IAuthorizer(this)
        );
        emit SetActionSet(acSet);

        _grantRole(DEFAULT_ADMIN_ROLE, regionSettings.governance());
        _grantRole(MANAGER_ROLE, _manager);
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType
    ) external {
        _revertIfActionControllerNotInLocation(_ac);
        _sendEvents(
            _entity,
            _entityID,
            _aType,
            _ac.execute(
                ILocation(address(this)),
                msg.sender,
                _entity,
                _entityID,
                _aType
            )
        );
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        address _param
    ) external {
        _revertIfActionControllerNotInLocation(_ac);
        _sendEvents(
            _entity,
            _entityID,
            _aType,
            _ac.execute(
                ILocation(address(this)),
                msg.sender,
                _entity,
                _entityID,
                _aType,
                _param
            )
        );
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        uint256 _param
    ) external {
        _revertIfActionControllerNotInLocation(_ac);
        _sendEvents(
            _entity,
            _entityID,
            _aType,
            _ac.execute(
                ILocation(address(this)),
                msg.sender,
                _entity,
                _entityID,
                _aType,
                _param
            )
        );
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        bytes32 _param
    ) external {
        _revertIfActionControllerNotInLocation(_ac);
        _sendEvents(
            _entity,
            _entityID,
            _aType,
            _ac.execute(
                ILocation(address(this)),
                msg.sender,
                _entity,
                _entityID,
                _aType,
                _param
            )
        );
    }

    function executeAction(
        IEntity _entity,
        uint256 _entityID,
        IActionController _ac,
        bytes32 _aType,
        bytes[] calldata _param
    ) external {
        _revertIfActionControllerNotInLocation(_ac);
        _sendEvents(
            _entity,
            _entityID,
            _aType,
            _ac.execute(
                ILocation(address(this)),
                msg.sender,
                _entity,
                _entityID,
                _aType,
                _param
            )
        );
    }

    function setRegionSettings(
        RegionSettings _regionSettings
    ) external onlyManager {
        regionSettings = _regionSettings;
        emit SetRegionSettings(regionSettings);
    }

    function _sendEvents(
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        bytes32[] memory events
    ) internal {
        for (uint256 i; i < events.length; i++) {
            bytes32 e = events[i];
            for (uint256 j; j < acSet.getLength(); j++) {
                IActionController a = IActionController(acSet.getAt(j));
                if (a.LISTEN_SET().getContains(e)) {
                    a.onEvent(
                        ILocation(address(this)),
                        msg.sender,
                        _entity,
                        _entityID,
                        _aType
                    );
                }
            }
        }
    }

    function _revertIfActionControllerNotInLocation(
        IActionController _ac
    ) internal view {
        if (!acSet.getContains(address(_ac))) {
            revert InvalidAction(_ac);
        }
    }

    function addActionController(IActionController _ac) external onlyManager {
        acSet.add(address(_ac));
        _ac.start();
    }

    function deleteActionController(
        IActionController _ac
    ) external onlyManager {
        acSet.remove(address(_ac));
        _ac.stop();
    }
}
