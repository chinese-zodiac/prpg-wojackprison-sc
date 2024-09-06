// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import {LocBase} from "../LocAbstracts/LocBase.sol";
import {LocTransferItem} from "../LocAbstracts/LocTransferItem.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {ILocation} from "../interfaces/ILocation.sol";
import {HasRegionSettings} from "../utils/HasRegionSettings.sol";
import {PlayerCharacters} from "../PlayerCharacters.sol";
import {EntityStoreERC20} from "../EntityStoreERC20.sol";
import {EntityStoreERC721} from "../EntityStoreERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";

contract LocationSpawnPoint is LocBase, LocTransferItem {
    using SafeERC20 for IERC20;

    bytes32 public constant WHITELIST_MANAGER =
        keccak256(abi.encodePacked("WHITELIST_MANAGER"));

    PlayerCharacters public immutable playerCharacters;

    //TODO: Switch to enumberable set
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
        RegionSettings _regionSettings,
        EnumerableSetAccessControlViewableAddress _validSourceSet,
        EnumerableSetAccessControlViewableAddress _validDestinationSet
    )
        HasRegionSettings(_regionSettings)
        LocBase(_validSourceSet, _validDestinationSet)
    {}

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
        EntityStoreERC20 erc20Store = regionSettings.entityStoreERC20();
        _token.safeTransferFrom(msg.sender, address(this), _wad);
        _token.approve(address(erc20Store), _wad);
        erc20Store.deposit(
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
        regionSettings.entityStoreERC20().withdraw(
            playerCharacters,
            _playerID,
            _token,
            _wad
        );
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
