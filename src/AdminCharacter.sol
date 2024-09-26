// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Entity} from "./Entity.sol";
import {Counters} from "./libs/Counters.sol";
import {IExecutor} from "./interfaces/IExecutor.sol";
import {ISpawner} from "./interfaces/ISpawner.sol";

contract AdminCharacter is Entity {
    using Counters for Counters.Counter;
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");

    constructor(
        IExecutor _executor,
        ISpawner _spawner
    ) Entity("Administrator, PRPG", "ADMIN-PRPG", _executor, _spawner) {}

    function tokenURI(uint256) public pure override returns (string memory) {
        return
            "ipfs://bafkreichjhb753uxpds2vy7mk3zruqz5bhonclrlfvden6ynfooku7wm2u";
    }
}
