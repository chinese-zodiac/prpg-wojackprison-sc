// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import {IEntity} from "./interfaces/IEntity.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";

//Permisionless EntityStoreERC20
//Deposit/withdraw/transfer tokens that are stored to a particular entity
//deposit/withdraw/transfers are restricted to the entity's current location.
contract EntityStoreERC20 is Ownable, Pausable {
    using SafeERC20 for IERC20;

    mapping(IERC721 entity => mapping(uint256 entityId => mapping(IERC20 token => uint256 shares)))
        public entityStoredERC20Shares;
    //Neccessary for rebasing, tax, liquid staking, or other tokens
    //that may directly modify this contract's balance.
    mapping(IERC20 token => uint256 shares) public totalShares;
    //Initial precision for shares per token
    uint256 internal constant SHARES_PRECISION = 10 ** 8;

    ILocationController public immutable locationController;

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

    error OnlyEntityLocation(address sender, IEntity entity, uint256 entityId);

    modifier onlyEntitysLocation(IEntity _entity, uint256 _entityId) {
        if (
            msg.sender !=
            address(locationController.entityIdLocation(_entity, _entityId))
        ) {
            revert OnlyEntityLocation(msg.sender, _entity, _entityId);
        }
        _;
    }

    constructor(ILocationController _locationController) Ownable(msg.sender) {
        locationController = _locationController;
    }

    function deposit(
        IEntity _entity,
        uint256 _entityId,
        IERC20 _token,
        uint256 _wad
    ) external onlyEntitysLocation(_entity, _entityId) whenNotPaused {
        uint256 expectedShares = convertTokensToShares(_token, _wad);
        uint256 initialTokens = _token.balanceOf(address(this));
        _token.safeTransferFrom(
            address(locationController.entityIdLocation(_entity, _entityId)),
            address(this),
            _wad
        );
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
        uint256 _wad
    ) external onlyEntitysLocation(_entity, _entityId) whenNotPaused {
        uint256 shares = convertTokensToShares(_token, _wad);
        entityStoredERC20Shares[_entity][_entityId][_token] -= shares;
        totalShares[_token] -= shares;
        _token.safeTransfer(
            address(locationController.entityIdLocation(_entity, _entityId)),
            _wad
        );
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
        onlyEntitysLocation(_fromEntity, _fromEntityId)
        onlyEntitysLocation(_toEntity, _toEntityId)
        whenNotPaused
    {
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
    }

    function burn(
        IEntity _entity,
        uint256 _entityId,
        ERC20Burnable _token,
        uint256 _wad
    ) external onlyEntitysLocation(_entity, _entityId) whenNotPaused {
        uint256 shares = convertTokensToShares(_token, _wad);
        entityStoredERC20Shares[_entity][_entityId][_token] -= shares;
        totalShares[_token] -= shares;
        _token.burn(_wad);
        emit Burn(_entity, _entityId, _token, _wad);
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
    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    //Emergency pause/unpause
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
