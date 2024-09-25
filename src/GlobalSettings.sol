// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {Authorizer} from "./Authorizer.sol";
import {EnumerableSetAccessControlViewableBytes32} from "./utils/EnumerableSetAccessControlViewableBytes32.sol";
import {TenXBlacklistV2} from "./TenXBlacklist.sol";
import {IKey} from "./interfaces/IKey.sol";

contract GlobalSettings is Authorizer {
    address public governance;
    TenXBlacklistV2 public tenXBlacklist;
    EnumerableSetAccessControlViewableBytes32 public registryKeySet;
    mapping(bytes32 registryKey => address registry) public registries;

    event SetGovernance(address governance);
    event SetTenXBlacklist(TenXBlacklistV2 tenXBlacklist);
    event SetRegistryKeySet(
        EnumerableSetAccessControlViewableBytes32 registryKeySet
    );
    event AddRegistry(bytes32 registryKey, address registry);
    event DeleteRegistry(bytes32 registryKey, address registry);

    error DuplicateKey(bytes32 registryKey);
    error InvalidKey(bytes32 key);
    error InvalidRegistry(address registry);

    constructor(address _governance, TenXBlacklistV2 _tenXBlacklist) {
        governance = _governance;
        tenXBlacklist = _tenXBlacklist;
        registryKeySet = new EnumerableSetAccessControlViewableBytes32(this);
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(MANAGER_ROLE, address(this));
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
    ) external onlyManager {
        tenXBlacklist = _tenXBlacklist;
        emit SetTenXBlacklist(tenXBlacklist);
    }
}
