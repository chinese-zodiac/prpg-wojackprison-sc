// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Entity} from "./Entity.sol";
import {CheapRNG} from "./CheapRNG.sol";
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";
import {EnumerableSetAccessControlViewableBytes32} from "./utils/EnumerableSetAccessControlViewableBytes32.sol";
import {Authorizer} from "./Authorizer.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Counters} from "./libs/Counters.sol";
import {DatastoreEntityLocation} from "./datastores/DatastoreEntityLocation.sol";
import {Executor} from "./Executor.sol";
import {ModifierOnlyExecutor} from "./utils/ModifierOnlyExecutor.sol";

contract AdminCharacter is Entity, Authorizer {
    using Counters for Counters.Counter;
    bytes32 public constant DATASTORE_ENTITY_LOCATION =
        keccak256("DATASTORE_ENTITY_LOCATION");

    constructor(
        Executor _executor
    ) Entity("Administrator, PRPG", "ADMIN-PRPG", _executor) {}

    function tokenURI(uint256) public pure override returns (string memory) {
        return
            "ipfs://bafkreichjhb753uxpds2vy7mk3zruqz5bhonclrlfvden6ynfooku7wm2u";
    }
}
