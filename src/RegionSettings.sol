// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessRoleManager} from "./AccessRoleManager.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "./utils/EnumerableSetAccessControlViewableBytes32.sol";
import {IEntity} from "./interfaces/IEntity.sol";
import {CheapRNG} from "./CheapRNG.sol";
import {BoostedValueCalculator} from "./BoostedValueCalculator.sol";
import {ActionControllerRegistry} from "./ActionControllerRegistry.sol";
import {EntityStoreERC20} from "./EntityStoreERC20.sol";
import {EntityStoreERC721} from "./EntityStoreERC721.sol";

contract RegionSettings is AccessRoleManager {
    address public governance;
    address public taxReceiver;
    uint256 public taxBps;
    IEntity public player;
    CheapRNG public cheapRng;
    EnumerableSetAccessControlViewableBytes32 public eTypesSet;
    EnumerableSetAccessControlViewableAddress public validEntitySet;
    EnumerableSetAccessControlViewableAddress public spawnPointsSet;
    ActionControllerRegistry public actionControllerRegistry;
    EntityStoreERC20 public entityStoreERC20;
    EntityStoreERC721 public entityStoreERC721;
    EnumerableSetAccessControlViewableAddress public transferableItemsSet;
    BoostedValueCalculator public boostedValueCalculator;
    ERC20Burnable public combatToken;

    event SetGovernance(address governance);
    event SetTaxReceiver(address taxReceiver);
    event SetTaxBps(uint256 taxBps);
    event SetPlayer(IEntity player);
    event SetCheapRng(CheapRNG cheapRng);
    event SetETypesSet(EnumerableSetAccessControlViewableBytes32 eTypesSet);
    event SetValidEntitySet(
        EnumerableSetAccessControlViewableAddress validEntitySet
    );
    event SetSpawnPointsSet(
        EnumerableSetAccessControlViewableAddress spawnPointsSet
    );
    event SetActionControllerRegistry(
        ActionControllerRegistry actionControllerRegistry
    );
    event SetEntityStoreERC20(EntityStoreERC20 entityStoreERC20);
    event SetEntityStoreERC721(EntityStoreERC721 entityStoreERC721);
    event SetTransferableItemsSet(
        EnumerableSetAccessControlViewableAddress transferableItemsSet
    );
    event SetBoostedValueCalculator(
        BoostedValueCalculator boostedValueCalculator
    );
    event SetCombatToken(ERC20Burnable combatToken);

    constructor(
        address _governance,
        address _taxReceiver,
        uint256 _taxBps,
        IEntity _player,
        CheapRNG _cheapRng,
        EnumerableSetAccessControlViewableBytes32 _eTypesSet,
        EnumerableSetAccessControlViewableAddress _validEntitySet,
        EnumerableSetAccessControlViewableAddress _spawnPointsSet,
        ActionControllerRegistry _actionControllerRegistry,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721,
        EnumerableSetAccessControlViewableAddress _transferableItemsSet,
        BoostedValueCalculator _boostedValueCalculator,
        ERC20Burnable _combatToken
    ) {
        governance = _governance;
        taxReceiver = _taxReceiver;
        taxBps = _taxBps;
        player = _player;
        cheapRng = _cheapRng;
        eTypesSet = _eTypesSet;
        validEntitySet = _validEntitySet;
        spawnPointsSet = _spawnPointsSet;
        actionControllerRegistry = _actionControllerRegistry;
        entityStoreERC20 = _entityStoreERC20;
        entityStoreERC721 = _entityStoreERC721;
        transferableItemsSet = _transferableItemsSet;
        boostedValueCalculator = _boostedValueCalculator;
        combatToken = _combatToken;
        emit SetGovernance(governance);
        emit SetTaxReceiver(taxReceiver);
        emit SetTaxBps(taxBps);
        emit SetPlayer(player);
        emit SetCheapRng(cheapRng);
        emit SetETypesSet(eTypesSet);
        emit SetValidEntitySet(validEntitySet);
        emit SetSpawnPointsSet(spawnPointsSet);
        emit SetActionControllerRegistry(actionControllerRegistry);
        emit SetEntityStoreERC20(entityStoreERC20);
        emit SetEntityStoreERC721(entityStoreERC721);
        emit SetTransferableItemsSet(transferableItemsSet);
        emit SetBoostedValueCalculator(boostedValueCalculator);
        emit SetCombatToken(combatToken);
    }

    function setGovernance(address _governance) external onlyManager {
        governance = _governance;
        emit SetGovernance(governance);
    }
    function setTaxReceiver(address _taxReceiver) external onlyManager {
        taxReceiver = _taxReceiver;
        emit SetTaxReceiver(taxReceiver);
    }
    function setTaxBps(uint256 _taxBps) external onlyManager {
        taxBps = _taxBps;
        emit SetTaxBps(taxBps);
    }
    function setPlayer(IEntity _player) external onlyManager {
        player = _player;
        emit SetPlayer(player);
    }
    function setCheapRng(CheapRNG _cheapRng) external onlyManager {
        cheapRng = _cheapRng;
        emit SetCheapRng(cheapRng);
    }
    function setETypesSet(
        EnumerableSetAccessControlViewableBytes32 _eTypesSet
    ) external onlyManager {
        eTypesSet = _eTypesSet;
        emit SetETypesSet(eTypesSet);
    }
    function setValidEntitySet(
        EnumerableSetAccessControlViewableAddress _validEntitySet
    ) external onlyManager {
        validEntitySet = _validEntitySet;
        emit SetValidEntitySet(validEntitySet);
    }
    function setSpawnPointsSet(
        EnumerableSetAccessControlViewableAddress _spawnPointsSet
    ) external onlyManager {
        spawnPointsSet = _spawnPointsSet;
        emit SetSpawnPointsSet(spawnPointsSet);
    }
    function setActionControllerRegistry(
        ActionControllerRegistry _actionControllerRegistry
    ) external onlyManager {
        actionControllerRegistry = _actionControllerRegistry;
        emit SetActionControllerRegistry(actionControllerRegistry);
    }
    function setEntityStoreERC20(
        EntityStoreERC20 _entityStoreERC20
    ) external onlyManager {
        entityStoreERC20 = _entityStoreERC20;
        emit SetEntityStoreERC20(entityStoreERC20);
    }
    function setEntityStoreERC721(
        EntityStoreERC721 _entityStoreERC721
    ) external onlyManager {
        entityStoreERC721 = _entityStoreERC721;
        emit SetEntityStoreERC721(entityStoreERC721);
    }
    function setTransferableItemsSet(
        EnumerableSetAccessControlViewableAddress _transferableItemsSet
    ) external onlyManager {
        transferableItemsSet = _transferableItemsSet;
        emit SetTransferableItemsSet(transferableItemsSet);
    }
    function setBoostedValueCalculator(
        BoostedValueCalculator _boostedValueCalculator
    ) external onlyManager {
        boostedValueCalculator = _boostedValueCalculator;
        emit SetBoostedValueCalculator(boostedValueCalculator);
    }
    function setCombatToken(ERC20Burnable _combatToken) external onlyManager {
        combatToken = _combatToken;
        emit SetCombatToken(combatToken);
    }
}
