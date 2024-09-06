// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {ILocationController} from "../interfaces/ILocationController.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {BoostedValueCalculator} from "../BoostedValueCalculator.sol";
import {TokenBase} from "../TokenBase.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {EntityStoreERC20} from "../EntityStoreERC20.sol";
import {EntityStoreERC721} from "../EntityStoreERC721.sol";
import {LocBase} from "../LocAbstracts/LocBase.sol";
import {LocPlayerWithStats} from "../LocAbstracts/LocPlayerWithStats.sol";
import {LocResource} from "../LocAbstracts/LocResource.sol";
import {LocCombat} from "../LocAbstracts/LocCombat.sol";
import {LocPrepareMove} from "../LocAbstracts/LocPrepareMove.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {HasRegionSettings} from "../utils/HasRegionSettings.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";

contract LocationWorldResource is LocPrepareMove, LocCombat, LocResource {
    constructor(
        RegionSettings _regionSettings,
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet,
        TokenBase _resourceToken,
        uint256 _baseProdDaily,
        uint64 _travelTime
    )
        HasRegionSettings(_regionSettings)
        LocPrepareMove(_travelTime)
        LocResource(_resourceToken, _baseProdDaily)
        LocBase(_validSourceSet, _validDestinationSet)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityID,
        ILocation _from
    ) public virtual override(LocBase, LocResource) {
        LocBase.LOCATION_CONTROLLER_onArrival(_entity, _entityID, _from);
        LocResource.LOCATION_CONTROLLER_onArrival(_entity, _entityID, _from);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    ) public virtual override(LocBase, LocPrepareMove, LocResource) {
        LocBase.LOCATION_CONTROLLER_onDeparture(_entity, _entityID, _to);
        LocResource.LOCATION_CONTROLLER_onDeparture(_entity, _entityID, _to);
        LocPrepareMove.LOCATION_CONTROLLER_onDeparture(_entity, _entityID, _to);
    }

    function _onPrepareMove(uint256 playerID) internal override {
        _haltPlayerProduction(playerID);
    }

    function attack(
        uint256 attackerPlayerID,
        uint256 defenderPlayerID
    ) public override {
        LocCombat.attack(attackerPlayerID, defenderPlayerID);
        _haltPlayerProduction(defenderPlayerID);
        _startPlayerProduction(defenderPlayerID);
        _haltPlayerProduction(attackerPlayerID);
        _startPlayerProduction(attackerPlayerID);
    }
}
