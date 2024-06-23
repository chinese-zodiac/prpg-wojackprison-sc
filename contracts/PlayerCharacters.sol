// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "./Entity.sol";
import "./interfaces/ILocationController.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract PlayerCharacters is Entity {
    mapping(uint256 => uint256) public gangIdToName;
    bytes32 public constant SPAWN_MANAGER = keccak256("SPAWN_MANAGER");

    mapping(ILocation spawnPoint => bool isValid) public isSpawnPointValid;

    constructor(
        ILocationController _locationController,
        string memory name,
        string memory symbol
    ) Entity(name, symbol, _locationController) {}

    function mint(
        address _to,
        ILocation _location
    ) public override returns (uint256 id_) {
        require(isSpawnPointValid[_location], "Invalid spawn");
        id_ = Entity.mint(_to, _location);
    }

    function setIsSpawnValid(
        ILocation location,
        bool isValid
    ) external onlyRole(SPAWN_MANAGER) {
        isSpawnPointValid[location] = isValid;
    }
}
