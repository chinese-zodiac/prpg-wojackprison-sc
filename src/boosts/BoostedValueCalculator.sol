// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IBooster} from "../interfaces/IBooster.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {EnumerableSetAccessControlViewableBytes32} from "../utils/EnumerableSetAccessControlViewableBytes32.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";
import {Authorizer} from "../Authorizer.sol";
import {ManagerRole} from "../roles/ManagerRole.sol";

//WARNING: Setting too many IBooster for a keyHash could make the gas cost explode
contract BoostedValueCalculator is ManagerRole, Authorizer {
    mapping(bytes32 keyHash => EnumerableSetAccessControlViewableAddress set) boosterSet;

    event SetBoostersMulSet(
        bytes32 keyHash,
        EnumerableSetAccessControlViewableAddress set
    );
    event SetBoostersMulAdd(
        bytes32 keyHash,
        EnumerableSetAccessControlViewableAddress set
    );

    constructor(address governance, address manager) {
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(MANAGER_ROLE, manager);
    }

    function getBoosterAccSum(
        ILocation at,
        bytes32 keyHash,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 basePower_) {
        EnumerableSetAccessControlViewableAddress set = boosterSet[keyHash];
        uint256 length = set.getLength();
        for (uint i; i < length; i++) {
            basePower_ += IBooster(set.getAt(i)).getBoost(at, entity, entityId);
        }
    }

    function getBoosterAccMul(
        ILocation at,
        bytes32 keyHash,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 basePower_) {
        EnumerableSetAccessControlViewableAddress set = boosterSet[keyHash];
        uint256 length = set.getLength();
        basePower_ = 10_000;
        for (uint i; i < length; i++) {
            basePower_ =
                (basePower_ *
                    IBooster(set.getAt(i)).getBoost(at, entity, entityId)) /
                10_000;
        }
    }
}
