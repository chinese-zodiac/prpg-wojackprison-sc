// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Entity} from "./Entity.sol";
import {CheapRNG} from "./CheapRNG.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "./utils/EnumerableSetAccessControlViewableBytes32.sol";
import {Authorizer} from "./Authorizer.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Executor} from "./Executor.sol";
import {ModifierOnlyExecutor} from "./utils/ModifierOnlyExecutor.sol";

contract PlayerCharacter is ModifierOnlyExecutor, Entity {
    bytes32 public constant IPFS_MANAGER = keccak256("IPFS_MANAGER");

    mapping(uint256 playerID => string ipfsHash) public metadataIpfsHash;

    event SetIPFSMetadataHash(uint256 playerID, string ipfsHash);

    event SetSpawnLocationsSet(
        EnumerableSetAccessControlViewableAddress SetSpawnLocationsSet
    );

    constructor(
        string memory name,
        string memory symbol,
        Executor _executor
    ) Entity(name, symbol, _executor) {
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

    function supportsInterface(
        bytes4 id
    )
        public
        view
        virtual
        override(AccessControlEnumerable, Entity)
        returns (bool)
    {
        return
            AccessControlEnumerable.supportsInterface(id) ||
            Entity.supportsInterface(id);
    }
}
