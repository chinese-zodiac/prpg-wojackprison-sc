// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {IExecutor} from "../interfaces/IExecutor.sol";
import {AccessRoleAdmin} from "../roles/AccessRoleAdmin.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {IRegistryRegistrar} from "../interfaces/IRegistryRegistrar.sol";
import {IKey} from "../interfaces/IKey.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

//Anyone can be a registrar and add/del entries.
contract RegistryBase is AccessControlEnumerable, ModifierBlacklisted {
    bytes32 public constant REGISTRY_REGISTRAR =
        keccak256("REGISTRY_REGISTRAR");
    IExecutor internal immutable X;
    mapping(address registrar => EACSetAddress set) public registrarEntrySet;
    mapping(bytes32 key => IKey entry) public entries;

    error KeyAlreadyRegistered(bytes32 key);
    error AlreadyRegistered(IKey entry);
    error NotRegistered(IKey entry);
    error EntryLacksKey(IKey entry);
    error EntryKeyAlreadyRegistered(IKey key);
    error KeyDoesNotExist(bytes32 key);

    constructor(IExecutor _executor) {
        X = _executor;
        _grantRole(DEFAULT_ADMIN_ROLE, X.globalSettings().governance());
    }

    modifier onlyRegistrar() {
        IRegistryRegistrar(X.globalSettings().registries(REGISTRY_REGISTRAR))
            .revertIfNotRegistrar(msg.sender);
        _;
    }

    function revertIfKeyDoesNotExist(bytes32 _key) external view {
        if (address(entries[_key]) == address(0x0)) {
            revert KeyDoesNotExist(_key);
        }
    }

    function addEntry(
        IKey entry
    ) external onlyRegistrar blacklisted(X, msg.sender) {
        EACSetAddress set = registrarEntrySet[msg.sender];
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

    function removeEntry(
        IKey entry
    ) external onlyRegistrar blacklisted(X, msg.sender) {
        EACSetAddress set = registrarEntrySet[msg.sender];
        if (set.getContains(address(entry))) {
            revert NotRegistered(entry);
        }
        set.remove(address(entry));
        delete entries[entry.KEY()];
    }
}
