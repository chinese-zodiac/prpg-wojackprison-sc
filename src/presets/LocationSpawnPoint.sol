// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "../LocationBase.sol";
import "../LocWithTokenStore.sol";
import "../PlayerCharacters.sol";
import "../EntityStoreERC20.sol";
import "../EntityStoreERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract LocationSpawnPoint is LocationBase, LocWithTokenStore {
    using SafeERC20 for IERC20;

    bytes32 public constant WHITELIST_MANAGER =
        keccak256(abi.encodePacked("WHITELIST_MANAGER"));

    PlayerCharacters public immutable playerCharacters;

    mapping(address token => bool isValid) public isTokenWhitelisted;

    struct SpawnRequirements {
        uint256 spawnCap;
        uint256 spawnCurrent;
        uint256 wad;
        IERC20 token;
    }
    mapping(bytes32 eType => SpawnRequirements spawnRequirements)
        internal spawnRequirements;

    constructor(
        ILocationController _locationController,
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet,
        EnumerableSetAccessControlViewableAddress _validEntitySet,
        PlayerCharacters _playerCharacters,
        EntityStoreERC20 _entityStoreERC20,
        EntityStoreERC721 _entityStoreERC721
    )
        LocationBase(
            _locationController,
            _validSourceSet,
            _validDestinationSet,
            _validEntitySet
        )
        LocWithTokenStore(_entityStoreERC20, _entityStoreERC721)
    {
        playerCharacters = _playerCharacters;
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

    function requestSpawnPlayerCharacter(
        bytes32 eType,
        address receiver
    ) public {
        SpawnRequirements storage reqs = spawnRequirements[eType];
        require(reqs.spawnCap > reqs.spawnCurrent, "Over spawn cap for eType");
        playerCharacters.requestMint(ILocation(this), eType, receiver);
        spawnRequirements[eType].spawnCurrent++;
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

    function getSpawnRequirements(
        bytes32 eType
    )
        external
        view
        returns (
            uint256 spawnCap_,
            uint256 spawnCurrent_,
            uint256 wad_,
            IERC20 token_
        )
    {
        SpawnRequirements storage reqs = spawnRequirements[eType];
        spawnCap_ = reqs.spawnCap;
        spawnCurrent_ = reqs.spawnCurrent;
        wad_ = reqs.wad;
        token_ = reqs.token;
    }
}
