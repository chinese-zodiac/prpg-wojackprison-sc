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
import {LocWithTokenStore} from "../LocWithTokenStore.sol";
import {LocationBase} from "../LocationBase.sol";
import {LocPlayerWithStats} from "../LocPlayerWithStats.sol";
import {LocResource} from "../LocResource.sol";
import {LocCombat} from "../LocCombat.sol";
import {LocPrepareMove} from "../LocPrepareMove.sol";
import {LocWithTokenStore} from "../LocWithTokenStore.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";

contract LocationWorldResource is LocPrepareMove, LocCombat, LocResource {
    constructor(
        ILocationController _locationController,
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet,
        EnumerableSetAccessControlViewableAddress _validEntitySet,
        IEntity _player,
        BoostedValueCalculator _boostedValueCalculator,
        TokenBase _resourceToken,
        uint256 _baseProdDaily,
        ERC20Burnable _combatToken,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721,
        uint64 _travelTime
    )
        LocPrepareMove(_travelTime)
        LocResource(_resourceToken, _baseProdDaily)
        LocCombat(_combatToken)
        LocPlayerWithStats(_player, _boostedValueCalculator)
        LocationBase(
            _locationController,
            _validSourceSet,
            _validDestinationSet,
            _validEntitySet
        )
        LocWithTokenStore(_entityStoreERC20, _entityStoreERC721)
    {}

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onArrival(
        IEntity _entity,
        uint256 _entityID,
        ILocation _from
    ) public virtual override(ILocation, LocationBase, LocResource) {
        LocationBase.LOCATION_CONTROLLER_onArrival(_entity, _entityID, _from);
        LocResource.LOCATION_CONTROLLER_onArrival(_entity, _entityID, _from);
    }

    //Only callable by LOCATION_CONTROLLER
    function LOCATION_CONTROLLER_onDeparture(
        IEntity _entity,
        uint256 _entityID,
        ILocation _to
    )
        public
        virtual
        override(ILocation, LocationBase, LocPrepareMove, LocResource)
    {
        LocationBase.LOCATION_CONTROLLER_onDeparture(_entity, _entityID, _to);
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
