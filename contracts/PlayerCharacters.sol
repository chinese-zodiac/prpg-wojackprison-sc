// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./Entity.sol";
import "./CheapRNG.sol";
import "./interfaces/ILocationController.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract PlayerCharacters is Entity {
    bytes32 public constant SPAWN_MANAGER = keccak256("SPAWN_MANAGER");
    bytes32 public constant IPFS_MANAGER = keccak256("IPFS_MANAGER");

    CheapRNG public cheapRNG;

    mapping(ILocation spawnPoint => bool isValid) public isSpawnPointValid;

    mapping(uint256 playerID => string ipfsHash) public metadataIpfsHash;

    mapping(address requester => uint256 requestID) public mintRequests;
    mapping(uint256 requestID => bytes32 eType) public pendingEtype;
    mapping(uint256 requestID => ILocation location) public pendingLocation;
    mapping(uint256 requestID => address receiver) public pendingReceiver;

    constructor(
        ILocationController _locationController,
        string memory name,
        string memory symbol,
        CheapRNG _cheapRNG
    ) Entity(name, symbol, _locationController) {
        cheapRNG = _cheapRNG;
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
        for (uint i = 0; i < count; i++) {
            metadataIpfsHash[playerIDs[i]] = ipfsHashes[i];
        }
    }

    function requestMint(
        address _to,
        ILocation _location,
        bytes32 _eType
    ) external onlyRole(MINTER_ROLE) returns (uint256 requestID) {
        requestID = cheapRNG.requestRandom();
        mintRequests[_to] = requestID;
        pendingEtype[requestID] = _eType;
        pendingLocation[requestID] = _location;
        pendingReceiver[requestID] = _to;
    }

    function finalizeMint(
        uint256 requestID
    ) external onlyRole(MINTER_ROLE) returns (uint256 nftID) {
        nftID = _mint(
            pendingReceiver[requestID],
            pendingLocation[requestID],
            pendingEtype[requestID],
            cheapRNG.fullfillRandom(requestID)
        );
        delete pendingEtype[requestID];
        delete pendingLocation[requestID];
        delete pendingReceiver[requestID];
    }

    function setCheapRNG(CheapRNG _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cheapRNG = _to;
    }
}
