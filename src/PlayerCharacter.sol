// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Entity} from "./Entity.sol";
import {EACSetAddress} from "./utils/EACSetAddress.sol";
import {IExecutor} from "./interfaces/IExecutor.sol";
import {ISpawner} from "./interfaces/ISpawner.sol";
import {ModifierOnlyExecutor} from "./utils/ModifierOnlyExecutor.sol";

contract PlayerCharacter is ModifierOnlyExecutor, Entity {
    bytes32 public constant IPFS_MANAGER = keccak256("IPFS_MANAGER");

    mapping(uint256 playerID => string ipfsHash) public metadataIpfsHash;

    event SetIPFSMetadataHash(uint256 playerID, string ipfsHash);

    event SetSpawnLocationsSet(EACSetAddress SetSpawnLocationsSet);

    constructor(
        string memory name,
        string memory symbol,
        IExecutor _executor,
        ISpawner _spawner
    ) Entity(name, symbol, _executor, _spawner) {
        _grantRole(IPFS_MANAGER, msg.sender);
    }

    function tokenURI(
        uint256 playerID
    ) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://", metadataIpfsHash[playerID]));
    }

    function setIPFSMetadataHashes(
        uint256[] calldata playerIDs,
        string[] calldata ipfsHashes
    ) external onlyRole(IPFS_MANAGER) {
        uint256 count = playerIDs.length;
        for (uint256 i = 0; i < count; i++) {
            metadataIpfsHash[playerIDs[i]] = ipfsHashes[i];
            emit SetIPFSMetadataHash(playerIDs[i], ipfsHashes[i]);
        }
    }
}
