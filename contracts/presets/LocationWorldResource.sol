// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;
import "../LocResource.sol";
import "../LocCombat.sol";
import "../LocPrepareMove.sol";

contract LocationWorldResource is LocPrepareMove, LocCombat, LocResource {
    constructor(
        ILocationController _locationController,
        IEntity _player,
        BoostedValueCalculator _boostedValueCalculator,
        TokenBase _resourceToken,
        uint256 _baseProdDaily,
        ERC20Burnable _combatToken,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721
    )
        LocResource(_resourceToken, _baseProdDaily)
        LocCombat(_combatToken)
        LocWithTokenStore(_entityStoreERC20, _entityStoreERC721)
        PlayerWithStats(_player, _boostedValueCalculator)
        LocationBase(_locationController)
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
