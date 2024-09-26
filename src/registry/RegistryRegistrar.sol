// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {IExecutor} from "../interfaces/IExecutor.sol";
import {AccessRoleAdmin} from "../roles/AccessRoleAdmin.sol";
import {ModifierBlacklisted} from "../utils/ModifierBlacklisted.sol";
import {IRegistryRegistrar} from "../interfaces/IRegistryRegistrar.sol";
import {EACSetAddress} from "../utils/EACSetAddress.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

contract RegistryRegistrar is
    AccessControlEnumerable,
    AccessRoleAdmin,
    ModifierBlacklisted,
    IRegistryRegistrar
{
    bytes32 public constant KEY = keccak256("REGISTRY_REGISTRAR");
    IExecutor internal immutable X;
    mapping(address registrar => string ipfsCID)
        public registrarMetadataIpfsCID;
    EACSetAddress public registrarSet;

    event BecomeRegistrar(address registrar);

    error OnlyRegistrar(address registrar);
    error AlreadyRegistrar(address registrar);

    modifier onlyRegistrar() {
        revertIfNotRegistrar(msg.sender);
        _;
    }

    constructor(IExecutor _executor) {
        X = _executor;
        _grantRole(DEFAULT_ADMIN_ROLE, X.globalSettings().governance());
    }

    function disableRegistrar(address registrar) external onlyAdmin {
        registrarSet.remove(registrar);
    }

    function enableRegistrar(address registrar) external onlyAdmin {
        registrarSet.add(registrar);
    }

    function revertIfNotRegistrar(address account) public view {
        if (!registrarSet.getContains(account)) {
            revert OnlyRegistrar(account);
        }
    }

    function becomeRegistrar() external blacklisted(X, msg.sender) {
        if (!registrarSet.getContains(msg.sender)) {
            registrarSet.add(msg.sender);
            emit BecomeRegistrar(msg.sender);
        } else {
            revert AlreadyRegistrar(msg.sender);
        }
    }

    function setRegistrarMetadataIpfsCid(
        string calldata ipfsCID
    ) external onlyRegistrar blacklisted(X, msg.sender) {
        registrarMetadataIpfsCID[msg.sender] = ipfsCID;
    }
}
