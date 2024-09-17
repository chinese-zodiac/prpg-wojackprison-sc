// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";
import {Authorizer} from "../Authorizer.sol";
import {Authorizer} from "../Authorizer.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {HasRSBlacklist} from "../utils/HasRSBlacklist.sol";
import {IRegistryRegistrar} from "../interfaces/IRegistryRegistrar.sol";
import {IKey} from "../interfaces/IKey.sol";

//Anyone can be a registrar and add/del entries.
contract RegistryBase is Authorizer, HasRSBlacklist {
    bytes32 public constant REGISTRY_REGISTRAR =
        keccak256("REGISTRY_REGISTRAR");
    mapping(address registrar => EnumerableSetAccessControlViewableAddress set)
        public registrarEntrySet;
    mapping(bytes32 key => IKey entry) public entries;

    error KeyAlreadyRegistered(bytes32 key);
    error AlreadyRegistered(IKey entry);
    error NotRegistered(IKey entry);
    error EntryLacksKey(IKey entry);
    error EntryKeyAlreadyRegistered(IKey key);

    constructor(RegionSettings _rs) HasRSBlacklist(_rs) {
        _grantRole(MANAGER_ROLE, address(this));
    }

    modifier onlyRegistrar() {
        IRegistryRegistrar(regionSettings.registries(REGISTRY_REGISTRAR))
            .revertIfNotRegistrar(msg.sender);
        _;
    }

    function addEntry(IKey entry) external onlyRegistrar blacklisted {
        EnumerableSetAccessControlViewableAddress set = registrarEntrySet[
            msg.sender
        ];
        if (set.getContains(address(entry))) {
            revert AlreadyRegistered(entry);
        }
        set.add(address(entry));
        bytes32 key = entry.KEY();
        if (key == bytes32(0x0)) {
            revert EntryLacksKey(entry);
        }
        if (entries[key] != IKey(address(0x0))) {
            revert KeyAlreadyRegistered(key);
        }
        entries[key] = entry;
    }

    function removeEntry(IKey entry) external onlyRegistrar blacklisted {
        EnumerableSetAccessControlViewableAddress set = registrarEntrySet[
            msg.sender
        ];
        if (set.getContains(address(entry))) {
            revert NotRegistered(entry);
        }
        set.remove(address(entry));
        delete entries[entry.KEY()];
    }
}
