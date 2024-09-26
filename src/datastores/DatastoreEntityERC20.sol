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
import {AccessRoleAdmin} from "../roles/AccessRoleAdmin.sol";
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {IKey} from "../interfaces/IKey.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Executor} from "../Executor.sol";

//Permisionless EntityERC20Datastore.
//Deposit/withdraw/transfer tokens that are stored to a particular entity
//deposit/withdraw/transfers are restricted to the entity's current location.
contract DatastoreEntityERC20 is
    ReentrancyGuard,
    ModifierOnlyExecutor,
    ModifierBlacklisted,
    AccessRoleAdmin,
    IKey
{
    bytes32 public constant KEY = keccak256("DATASTORE_ENTITY_ERC20");
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");
    using SafeERC20 for IERC20;

    Executor internal immutable X;

    mapping(IERC721 entity => mapping(uint256 entityId => mapping(IERC20 token => uint256 shares)))
        public entityStoredERC20Shares;

    mapping(IERC721 entity => mapping(uint256 entityId => EACSetAddress tokens))
        public entityStoredTokens;

    //Neccessary for rebasing, tax, liquid staking, or other tokens
    //that may directly modify this contract's balance.
    mapping(IERC20 token => uint256 shares) public totalShares;
    //Initial precision for shares per token
    uint256 internal constant SHARES_PRECISION = 10 ** 8;

    event Deposit(
        IEntity entity,
        uint256 entityId,
        IERC20 token,
        uint256 tokenWad
    );
    event Withdraw(
        IEntity entity,
        uint256 entityId,
        IERC20 token,
        uint256 tokenWad
    );
    event Burn(
        IEntity entity,
        uint256 entityId,
        IERC20 token,
        uint256 tokenWad
    );
    event Transfer(
        IEntity fromEntity,
        uint256 fromEntityId,
        IEntity toEntity,
        uint256 toEntityId,
        IERC20 token,
        uint256 tokenWad
    );

    constructor(Executor _executor) {
        X = _executor;
        _grantRole(DEFAULT_ADMIN_ROLE, X.globalSettings().governance());
    }

    function deposit(
        IEntity _entity,
        uint256 _entityId,
        IERC20 _token,
        uint256 _wad
    )
        external
        nonReentrant
        onlyExecutor(X)
        blacklistedEntity(X, _entity, _entityId)
    {
        if (_wad == 0) return;
        uint256 expectedShares = convertTokensToShares(_token, _wad);
        uint256 initialTokens = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _wad);
        //May be different than _wad due to transfer tax/burn
        uint256 deltaTokens = _token.balanceOf(address(this)) - initialTokens;
        uint256 newShares = (deltaTokens * expectedShares) / _wad;
        entityStoredERC20Shares[_entity][_entityId][_token] += newShares;
        totalShares[_token] += newShares;
        emit Deposit(_entity, _entityId, _token, _wad);
    }

    function withdraw(
        IEntity _entity,
        uint256 _entityId,
        IERC20 _token,
        uint256 _wad,
        address _receiver
    )
        external
        nonReentrant
        onlyExecutor(X)
        blacklistedEntity(X, _entity, _entityId)
    {
        if (_wad == 0) return;
        uint256 shares = convertTokensToShares(_token, _wad);
        entityStoredERC20Shares[_entity][_entityId][_token] -= shares;
        totalShares[_token] -= shares;
        _token.safeTransfer(_receiver, _wad);
        emit Withdraw(_entity, _entityId, _token, _wad);
    }

    function transfer(
        IEntity _fromEntity,
        uint256 _fromEntityId,
        IEntity _toEntity,
        uint256 _toEntityId,
        IERC20 _token,
        uint256 _wad
    )
        external
        nonReentrant
        onlyExecutor(X)
        blacklistedEntity(X, _fromEntity, _fromEntityId)
        blacklistedEntity(X, _toEntity, _toEntityId)
    {
        if (_wad == 0) return;

        DatastoreEntityLocation dsELoc = DatastoreEntityLocation(
            X.globalSettings().registries(DATASTORE_ENTITY_LOCATION)
        );
        dsELoc.revertIfEntityNotAtLocation(
            _toEntity,
            _toEntityId,
            dsELoc.entityLocation(_fromEntity, _fromEntityId)
        );
        uint256 shares = convertTokensToShares(_token, _wad);
        entityStoredERC20Shares[_fromEntity][_fromEntityId][_token] -= shares;
        entityStoredERC20Shares[_toEntity][_toEntityId][_token] += shares;
        emit Transfer(
            _fromEntity,
            _fromEntityId,
            _toEntity,
            _toEntityId,
            _token,
            _wad
        );
        deleteEntityUnusedTokens(_fromEntity, _fromEntityId, _token);
    }

    function burn(
        IEntity _entity,
        uint256 _entityId,
        ERC20Burnable _token,
        uint256 _wad
    )
        external
        nonReentrant
        onlyExecutor(X)
        blacklistedEntity(X, _entity, _entityId)
    {
        if (_wad == 0) return;
        uint256 shares = convertTokensToShares(_token, _wad);
        entityStoredERC20Shares[_entity][_entityId][_token] -= shares;
        totalShares[_token] -= shares;
        _token.burn(_wad);
        emit Burn(_entity, _entityId, _token, _wad);
        deleteEntityUnusedTokens(_entity, _entityId, _token);
    }

    function convertTokensToShares(
        IERC20 _token,
        uint256 _wad
    ) public view returns (uint256) {
        if (totalShares[_token] == 0) return _wad * SHARES_PRECISION;
        return (_wad * totalShares[_token]) / _token.balanceOf(address(this));
    }

    function getStoredER20WadFor(
        IEntity _entity,
        uint256 _entityId,
        IERC20 _token
    ) external view returns (uint256) {
        return
            (entityStoredERC20Shares[_entity][_entityId][_token] *
                _token.balanceOf(address(this))) / totalShares[_token];
    }

    function getSharesPerToken(IERC20 _token) external view returns (uint256) {
        if (totalShares[_token] == 0) return SHARES_PRECISION;
        return totalShares[_token] / _token.balanceOf(address(this));
    }

    //Escape hatch for emergency use
    function recoverERC20(
        address tokenAddress
    ) external nonReentrant onlyAdmin {
        IERC20(tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function updateSets(
        IEntity _entity,
        uint256 _entityId,
        IERC20 _token
    ) public {
        if (address(entityStoredTokens[_entity][_entityId]) == address(0x0)) {
            entityStoredTokens[_entity][_entityId] = new EACSetAddress();
        }
        if (
            !entityStoredTokens[_entity][_entityId].getContains(address(_token))
        ) {
            entityStoredTokens[_entity][_entityId].add(address(_token));
        }
    }

    function deleteEntityUnusedTokens(
        IEntity _entity,
        uint256 _entityId,
        IERC20 _token
    ) public {
        if (entityStoredERC20Shares[_entity][_entityId][_token] == 0) {
            entityStoredTokens[_entity][_entityId].remove(address(_token));
        }
    }
}
