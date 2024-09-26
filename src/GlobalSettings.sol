// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {EACSetBytes32} from "./utils/EACSetBytes32.sol";
import {TenXBlacklistV2} from "./TenXBlacklist.sol";
import {IKey} from "./interfaces/IKey.sol";
import {AccessRoleAdmin} from "./roles/AccessRoleAdmin.sol";
import {AccessRoleManager} from "./roles/AccessRoleManager.sol";

contract GlobalSettings is AccessRoleAdmin, AccessRoleManager {
    address public governance;
    TenXBlacklistV2 public tenXBlacklist;
    EACSetBytes32 public registryKeySet;
    mapping(bytes32 registryKey => address registry) public registries;

    event SetGovernance(address governance);
    event SetTenXBlacklist(TenXBlacklistV2 tenXBlacklist);
    event SetRegistryKeySet(EACSetBytes32 registryKeySet);
    event AddRegistry(bytes32 registryKey, address registry);
    event DeleteRegistry(bytes32 registryKey, address registry);

    error DuplicateKey(bytes32 registryKey);
    error InvalidKey(bytes32 key);
    error InvalidRegistry(address registry);

    constructor(address _governance, TenXBlacklistV2 _tenXBlacklist) {
        governance = _governance;
        tenXBlacklist = _tenXBlacklist;
        registryKeySet = new EACSetBytes32();
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        emit SetGovernance(governance);
        emit SetTenXBlacklist(tenXBlacklist);
        emit SetRegistryKeySet(registryKeySet);
    }

    function addRegistry(IKey registry) external onlyAdmin {
        bytes32 key = registry.KEY();
        if (registryKeySet.getContains(key)) revert DuplicateKey(key);
        if (key == bytes32(0x0)) revert InvalidKey(key);
        registryKeySet.add(key);
        registries[key] = address(registry);
        emit AddRegistry(key, address(registry));
    }

    function delRegistry(bytes32 key) external onlyAdmin {
        address registry = registries[key];
        if (!registryKeySet.getContains(key)) revert InvalidKey(key);
        registryKeySet.remove(key);
        delete registries[key];
        emit DeleteRegistry(key, registry);
    }

    function setGovernance(address _governance) external onlyAdmin {
        governance = _governance;
        emit SetGovernance(governance);
    }

    function setTenXBlacklist(
        TenXBlacklistV2 _tenXBlacklist
    ) external onlyAdmin {
        tenXBlacklist = _tenXBlacklist;
        emit SetTenXBlacklist(tenXBlacklist);
    }
}
