// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {Authorizer} from "../Authorizer.sol";
import {HasRSBlacklist} from "../utils/HasRSBlacklist.sol";
import {RegionSettings} from "../RegionSettings.sol";
import {IRegistryRegistrar} from "../interfaces/IRegistryRegistrar.sol";
import {EnumerableSetAccessControlViewableAddress} from "../utils/EnumerableSetAccessControlViewableAddress.sol";

contract RegistryRegistrar is Authorizer, HasRSBlacklist, IRegistryRegistrar {
    bytes32 public constant KEY = keccak256("REGISTRY_REGISTRAR");
    mapping(address registrar => string ipfsCID)
        public registrarMetadataIpfsCID;
    EnumerableSetAccessControlViewableAddress public registrarSet;

    event BecomeRegistrar(address registrar);

    error OnlyRegistrar(address registrar);
    error AlreadyRegistrar(address registrar);

    modifier onlyRegistrar() {
        revertIfNotRegistrar(msg.sender);
        _;
    }

    constructor(RegionSettings _rs) HasRSBlacklist(_rs) {
        _grantRole(MANAGER_ROLE, address(this));
    }

    function disableRegistrar(address registrar) external onlyAdmin {
        registrarSet.remove(registrar);
    }

    function enableRegistrar(address registrar) external onlyAdmin {
        registrarSet.remove(registrar);
    }

    function revertIfNotRegistrar(address account) public view {
        if (!registrarSet.getContains(account)) {
            revert OnlyRegistrar(account);
        }
    }

    function becomeRegistrar() external blacklisted {
        if (!registrarSet.getContains(msg.sender)) {
            registrarSet.add(msg.sender);
            emit BecomeRegistrar(msg.sender);
        } else {
            revert AlreadyRegistrar(msg.sender);
        }
    }

    function setRegistrarMetadataIpfsCid(
        string calldata ipfsCID
    ) external onlyRegistrar blacklisted {
        registrarMetadataIpfsCID[msg.sender] = ipfsCID;
    }
}
