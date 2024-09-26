// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IBooster} from "../interfaces/IBooster.sol";
import {IEntity} from "../interfaces/IEntity.sol";
import {EACSetBytes32} from "../utils/EACSetBytes32.sol";
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {ManagerRole} from "../roles/ManagerRole.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

//WARNING: Setting too many IBooster for a keyHash could make the gas cost explode
contract BoostedValueCalculator is ManagerRole, AccessControlEnumerable {
    mapping(bytes32 keyHash => EACSetAddress set) boosterSet;

    event SetBoostersMulSet(bytes32 keyHash, EACSetAddress set);
    event SetBoostersMulAdd(bytes32 keyHash, EACSetAddress set);

    constructor(address governance, address manager) {
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(MANAGER_ROLE, manager);
    }

    function getBoosterAccSum(
        uint256 atLocId,
        bytes32 keyHash,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 basePower_) {
        EACSetAddress set = boosterSet[keyHash];
        uint256 length = set.getLength();
        for (uint i; i < length; i++) {
            basePower_ += IBooster(set.getAt(i)).getBoost(
                atLocId,
                entity,
                entityId
            );
        }
    }

    function getBoosterAccMul(
        uint256 atLocId,
        bytes32 keyHash,
        IEntity entity,
        uint256 entityId
    ) external view returns (uint256 basePower_) {
        EACSetAddress set = boosterSet[keyHash];
        uint256 length = set.getLength();
        basePower_ = 10_000;
        for (uint i; i < length; i++) {
            basePower_ =
                (basePower_ *
                    IBooster(set.getAt(i)).getBoost(
                        atLocId,
                        entity,
                        entityId
                    )) /
                10_000;
        }
    }
}
