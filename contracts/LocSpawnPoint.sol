// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./LocationBase.sol";
import "./PlayerCharacters.sol";
import "./EntityStoreERC20.sol";
import "./EntityStoreERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract LocSpawnPoint is LocationBase {
    using SafeERC20 for IERC20;

    bytes32 public constant WHITELIST_MANAGER =
        keccak256(abi.encodePacked("WHITELIST_MANAGER"));

    PlayerCharacters public immutable playerCharacters;
    EntityStoreERC20 public immutable entityStoreERC20;
    EntityStoreERC721 public immutable entityStoreERC721;

    mapping(address token => bool isValid) public isTokenWhitelisted;

    struct SpawnCost {
        IERC20 token;
        uint256 wad;
    }
    mapping(PlayerCharacters.PLAYER_TYPE pType => SpawnCost spawnCost) public spawnCosts;

    constructor(
        ILocationController _locationController,
        PlayerCharacters _playerCharacters,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721
    ) LocationBase(_locationController) {
        playerCharacters = _playerCharacters;
        entityStoreERC20 = _entityStoreERC20;
        entityStoreERC721 = _entityStoreERC721;
    }

    function setNFTWhitelist(
        IERC721 _nft,
        bool isWhitelisted
    ) external onlyRole(WHITELIST_MANAGER) {
        isTokenWhitelisted[address(_nft)] = isWhitelisted;
        _nft.setApprovalForAll(address(entityStoreERC721), true);
    }

    function setIERC20Whitelist(
        IERC20 _token,
        bool isWhitelisted
    ) external onlyRole(WHITELIST_MANAGER) {
        isTokenWhitelisted[address(_token)] = isWhitelisted;
        _token.approve(address(entityStoreERC20), type(uint256).max);
    }

    function spawnPlayerCharacter(PlayerCharacters.PLAYER_TYPE pType) public {
        playerCharacters.mint(msg.sender, ILocation(this));
    }

    function depositIERC20(
        IERC20 _token,
        uint256 _playerID,
        uint256 _wad
    ) external {
        require(isTokenWhitelisted[address(_token)], "Not whitelisted");
        require(
            msg.sender == playerCharacters.ownerOf(_playerID),
            "Only player owner"
        );
        _token.safeTransferFrom(msg.sender, address(this), _wad);
        entityStoreERC20.deposit(
            playerCharacters,
            _playerID,
            _token,
            _token.balanceOf(address(this))
        );
    }

    function withdrawIERC20(
        IERC20 _token,
        uint256 _playerID,
        uint256 _wad
    ) external {
        entityStoreERC20.withdraw(playerCharacters, _playerID, _token, _wad);
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    function getSpawnCost()
}
