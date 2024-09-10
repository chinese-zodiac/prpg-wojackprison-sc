// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ActionController} from "../ActionController.sol";
import {IEntity} from "../../interfaces/IEntity.sol";
import {ILocation} from "../../interfaces/ILocation.sol";
import {IAuthorizer} from "../../interfaces/IAuthorizer.sol";
import {Timers} from "../../libs/Timers.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../../utils/EnumerableSetAccessControlViewableBytes32.sol";
import {EnumerableSetAccessControlViewableAddress} from "../../utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableUint256} from "../../utils/EnumerableSetAccessControlViewableUint256.sol";
import {MovementPreparation} from "./ACMoveStructs.sol";
import {ACRevertsLib} from "../ACRevertsLib.sol";
import {ACMoveRevertsLib} from "./ACMoveRevertsLib.sol";
import "../ACErrors.sol" as ACErrors;
import "./ACMoveErrors.sol" as ACMoveErrors;
import "../ACEvents.sol" as ACEvents;

contract ACMove is ActionController {
    using Timers for Timers.Timestamp;

    bytes32 public constant override AC_KEY = keccak256("AC_MOVE");

    mapping(ILocation location => mapping(IEntity entity => EnumerableSetAccessControlViewableUint256 entityIdSet))
        public locationEntityIdSet;
    mapping(IEntity entity => mapping(uint256 entityID => ILocation location))
        public entityIdLocation;

    mapping(ILocation location => EnumerableSetAccessControlViewableAddress set)
        public destinationSet;

    //Timed Travel
    //TODO: Figure out access control for travel time (should be location source manager?)
    mapping(ILocation source => mapping(ILocation destination => uint64 travelTime))
        public travelTime;

    mapping(IEntity entity => mapping(uint256 entityID => MovementPreparation preparation))
        public movePrepares;

    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME_ADD =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME_ADD"));
    bytes32 public constant BOOSTER_PLAYER_TRAVELTIME_MUL =
        keccak256(abi.encodePacked("BOOSTER_PLAYER_TRAVELTIME_MUL"));

    //actions
    bytes32 public constant ACTION_MOVE_DIRECT =
        keccak256("ACTION_MOVE_DIRECT");
    bytes32 public constant ACTION_MOVE_TIMED_PREPARE =
        keccak256("ACTION_MOVE_TIMED_PREPARE");
    bytes32 public constant ACTION_MOVE_TIMED_COMPLETE =
        keccak256("ACTION_MOVE_TIMED_COMPLETE");
    bytes32 public constant ACTION_SPAWN = keccak256("ACTION_SPAWN");
    bytes32 public constant ACTION_DESPAWN = keccak256("ACTION_DESPAWN");

    //setters
    bytes32 public constant SET_TRAVEL_TIME = keccak256("SET_TRAVEL_TIME");
    bytes32 public constant SET_DESTINATION = keccak256("SET_DESTINATION");
    bytes32 public constant SET_ISTIMED_TOGGLE =
        keccak256("SET_ISTIMED_TOGGLE");
    bytes32 public constant SET_ISTOKENREQ = keccak256("SET_ISTOKENREQ");
    bytes32 public constant SET_ISTOKENCOST = keccak256("SET_ISTOKENCOST");

    //events emitted
    bytes32 public constant EVENT_ON_MOVE_TIMED_PREPARE =
        keccak256("EVENT_ON_MOVE_TIMED_PREPARE");
    bytes32 public constant EVENT_ON_MOVE = keccak256("EVENT_ON_MOVE");

    //listeners
    //none

    event SetTravelTime(
        ILocation source,
        ILocation destination,
        uint256 travelTime
    );
    event SetIsDestinationTimed(ILocation location, bool isTimed);
    event PrepareMoveTimed(
        ILocation source,
        ILocation destination,
        IEntity entity,
        uint256 entityID,
        uint64 deadline
    );

    constructor() ActionController() {
        A_TYPE_SET = new EnumerableSetAccessControlViewableBytes32(
            IAuthorizer(this)
        );
        A_TYPE_SET.add(ACTION_MOVE_DIRECT);
        A_TYPE_SET.add(ACTION_MOVE_TIMED_PREPARE);
        A_TYPE_SET.add(ACTION_MOVE_TIMED_COMPLETE);
        aTypeParams[ACTION_MOVE_DIRECT] = PARAM.ADDRESS;
        aTypeParams[ACTION_MOVE_TIMED_PREPARE] = PARAM.ADDRESS;
        aTypeParams[ACTION_MOVE_TIMED_COMPLETE] = PARAM.NONE;
    }

    //TODO: Role management for destinationSet, and for setting timers, token payments
    function start() public override {
        destinationSet[
            ILocation(msg.sender)
        ] = new EnumerableSetAccessControlViewableAddress(
            IAuthorizer(msg.sender)
        );
    }
    function stop() public override {
        //TODO: Access control
        delete destinationSet[ILocation(msg.sender)];
    }

    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType
    ) public override returns (bytes32[] memory events_) {
        events_ = new bytes32[](1);
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
        ACMoveRevertsLib.revertIfEntityNotAtLocation(
            this,
            _location,
            _entity,
            _entityID
        );
        if (_aType == ACTION_MOVE_TIMED_COMPLETE) {
            _actionTimedMoveComplete(_location, _entity, _entityID);
            A_TYPE_ALLOWED_SET.remove(ACTION_MOVE_TIMED_COMPLETE);
            events_[0] = EVENT_ON_MOVE;
        } else {
            revert ACErrors.InvalidAType(_aType);
        }
        emit ACEvents.ActionSuccess(
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType
        );
    }

    function execute(
        ILocation _location,
        address _locCaller,
        IEntity _entity,
        uint256 _entityID,
        bytes32 _aType,
        address _param
    ) public override returns (bytes32[] memory events_) {
        events_ = new bytes32[](1);
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
        if (_aType == ACTION_MOVE_DIRECT) {
            _actionMove(_location, ILocation(_param), _entity, _entityID);
            events_[0] = EVENT_ON_MOVE;
        } else if (_aType == ACTION_MOVE_TIMED_PREPARE) {
            _actionTimedMovePrepare(
                _location,
                ILocation(_param),
                _entity,
                _entityID
            );
            A_TYPE_ALLOWED_SET.add(ACTION_MOVE_TIMED_COMPLETE);
            events_[0] = EVENT_ON_MOVE_TIMED_PREPARE;
        } else {
            revert ACErrors.InvalidAType(_aType);
        }
        emit ACEvents.ActionSuccess(
            _location,
            _locCaller,
            _entity,
            _entityID,
            _aType,
            _param
        );
    }

    function _move(
        ILocation _source,
        ILocation _destination,
        IEntity _entity,
        uint256 _entityID
    ) internal {
        if (_source != ILocation(address(0x0))) {
            locationEntityIdSet[_source][_entity].remove(_entityID);
        }
        if (_destination != ILocation(address(0x0))) {
            locationEntityIdSet[_destination][_entity].add(_entityID);
        }
        entityIdLocation[_entity][_entityID] = _destination;
    }

    function _actionTimedMoveComplete(
        ILocation _source,
        IEntity _entity,
        uint256 _entityID
    ) internal {
        ACMoveRevertsLib.revertIfMovementPreperationNotReady(
            movePrepares,
            _entity,
            _entityID
        );
        MovementPreparation storage movePrep = movePrepares[_entity][_entityID];
        _move(_source, movePrep.destination, _entity, _entityID);
        movePrep.readyTimer.reset();
        delete movePrep.destination;
    }

    function _actionTimedMovePrepare(
        ILocation _source,
        ILocation _destination,
        IEntity _entity,
        uint256 _entityID
    ) internal {
        ACMoveRevertsLib.revertIfInvalidDestination(
            destinationSet,
            _source,
            _destination
        );
        ACMoveRevertsLib.revertIfNotTimedDestination(
            travelTime,
            _source,
            _destination
        );
        MovementPreparation storage movePrep = movePrepares[_entity][_entityID];
        movePrep.destination = _destination;
        movePrep.readyTimer.setDeadline(
            uint64(block.timestamp) + travelTime[_source][_destination]
        );
        emit PrepareMoveTimed(
            _source,
            _destination,
            _entity,
            _entityID,
            movePrep.readyTimer.getDeadline()
        );
    }

    function _actionMove(
        ILocation _source,
        ILocation _destination,
        IEntity _entity,
        uint256 _entityID
    ) internal {
        ACMoveRevertsLib.revertIfInvalidDestination(
            destinationSet,
            _source,
            _destination
        );
        ACMoveRevertsLib.revertIfTimedDestination(
            travelTime,
            _source,
            _destination
        );
        _move(_source, _destination, _entity, _entityID);
    }
}
