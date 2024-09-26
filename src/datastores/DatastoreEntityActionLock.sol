// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "../interfaces/IEntity.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DatastoreEntityLocation} from "./DatastoreEntityLocation.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ModifierOnlyExecutor} from "../utils/ModifierOnlyExecutor.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {IKey} from "../interfaces/IKey.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Executor} from "../Executor.sol";

//Stores a Lock for an Action.
//Action calls Lock to set an Unlock Action key,
//Then when the Action that has the unlock action key  is called, it must call unlock.
contract DatastoreEntityActionLock is
    ReentrancyGuard,
    ModifierOnlyExecutor,
    ModifierBlacklisted,
    AccessControlEnumerable,
    IKey
{
    bytes32 public constant KEY = keccak256("DATASTORE_ENTITY_ACTION_LOCK");
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    using SafeERC20 for IERC20;

    Executor internal immutable X;

    mapping(IERC721 entity => mapping(uint256 entityId => bytes32 unlockActionKey))
        public entityActionLock;

    event Lock(IEntity entity, uint256 entityId, bytes32 unlockActionKey);

    event Unlock(IEntity entity, uint256 entityId, bytes32 unlockActionKey);

    error AlreadyLocked(
        IEntity entity,
        uint256 entityId,
        bytes32 currentUnlockActionKey,
        bytes32 attemptedUnlockActionKey
    );
    error NotLocked(IEntity entity, uint256 entityId, bytes32 actionKey);
    error InvalidUnlockActionKey(bytes32 unlockActionKey);
    error WrongUnlockActionKey(
        IEntity entity,
        uint256 entityId,
        bytes32 currentUnlockActionKey,
        bytes32 attemptedUnlockActionKey
    );

    constructor(Executor _executor) {
        X = _executor;
        _grantRole(DEFAULT_ADMIN_ROLE, X.globalSettings().governance());
    }

    function isLocked(
        IEntity entity,
        uint256 entityId,
        bytes32 actionKey
    ) external view returns (bool) {
        if (entityActionLock[entity][entityId] == bytes32(0x0)) return false;
        if (entityActionLock[entity][entityId] == actionKey) return false;
        return true;
    }

    function lock(
        IEntity _entity,
        uint256 _entityId,
        bytes32 _unlockActionKey
    )
        external
        nonReentrant
        onlyExecutor(X)
        blacklistedEntity(X, _entity, _entityId)
    {
        if (entityActionLock[_entity][_entityId] != bytes32(0x0)) {
            revert AlreadyLocked(
                _entity,
                _entityId,
                entityActionLock[_entity][_entityId],
                _unlockActionKey
            );
        }
        //TODO: Check DatastoreLocationActions
        /*if (!ILocation(msg.sender).actionSet().getContains(_unlockActionKey)) {
            revert InvalidUnlockActionKey(_unlockActionKey);
        }*/
        entityActionLock[_entity][_entityId] = _unlockActionKey;
        emit Lock(_entity, _entityId, _unlockActionKey);
    }

    function unlock(
        IEntity _entity,
        uint256 _entityId,
        bytes32 _unlockActionKey
    )
        external
        nonReentrant
        onlyExecutor(X)
        blacklistedEntity(X, _entity, _entityId)
    {
        if (entityActionLock[_entity][_entityId] != bytes32(0x0)) {
            revert NotLocked(_entity, _entityId, _unlockActionKey);
        }
        if (entityActionLock[_entity][_entityId] != _unlockActionKey) {
            revert WrongUnlockActionKey(
                _entity,
                _entityId,
                entityActionLock[_entity][_entityId],
                _unlockActionKey
            );
        }
        delete entityActionLock[_entity][_entityId];
        emit Unlock(_entity, _entityId, _unlockActionKey);
    }
}
