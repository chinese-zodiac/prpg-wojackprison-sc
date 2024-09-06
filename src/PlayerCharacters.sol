// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {RegionSettings} from "./RegionSettings.sol";
import {Entity} from "./Entity.sol";
import {CheapRNG} from "./CheapRNG.sol";
import {ILocation} from "./interfaces/ILocation.sol";
import {ILocationController} from "./interfaces/ILocationController.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "./utils/EnumerableSetAccessControlViewableBytes32.sol";

contract PlayerCharacters is Entity {
    bytes32 public constant IPFS_MANAGER = keccak256("IPFS_MANAGER");

    mapping(uint256 playerID => string ipfsHash) public metadataIpfsHash;

    struct MintRequest {
        bytes32 eType;
        ILocation location;
        address receiver;
    }

    mapping(uint256 requestID => MintRequest request) public requests;

    event SetIPFSMetadataHash(uint256 playerID, string ipfsHash);
    event RequestMint(
        uint256 requestID,
        bytes32 eType,
        ILocation location,
        address receiver
    );
    event FullfillMint(uint256 requestID, uint256 nftID, bytes32 randWord);
    event SetCheapRNG(CheapRNG cheapRNG);
    event SetETypesSet(EnumerableSetAccessControlViewableBytes32 eTypesSet);
    event SetSpawnPointsSet(
        EnumerableSetAccessControlViewableAddress spawnPointsSet
    );

    error RequestIDDoesNotExist(uint256 requestID);
    error CannotSpawnToZeroAddress(address receiver);

    constructor(
        string memory name,
        string memory symbol,
        RegionSettings _regionSettings
    ) Entity(name, symbol, _regionSettings) {}

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

    function requestMint(
        ILocation _location,
        bytes32 _eType,
        address _receiver
    ) external onlyRole(MINTER_ROLE) returns (uint256 requestID) {
        if (_receiver == address(0x0)) {
            revert CannotSpawnToZeroAddress(_receiver);
        }
        regionSettings.eTypesSet().revertIfNotInSet(_eType);
        regionSettings.spawnPointsSet().revertIfNotInSet(address(_location));
        requestID = regionSettings.cheapRng().requestRandom();
        MintRequest storage req = requests[requestID];
        req.location = _location;
        req.eType = _eType;
        req.receiver = _receiver;
        emit RequestMint(requestID, _eType, _location, _receiver);
    }

    function fullfillMint(uint256 _requestID) external returns (uint256 nftID) {
        MintRequest storage req = requests[_requestID];
        if (req.receiver == address(0x0)) {
            revert RequestIDDoesNotExist(_requestID);
        }
        bytes32 randWord = regionSettings.cheapRng().fullfillRandom(_requestID);
        nftID = _mint(req.receiver, req.location, req.eType, randWord);
        emit FullfillMint(_requestID, nftID, randWord);
        delete req.receiver;
        delete req.eType;
        delete req.location;
    }
}
