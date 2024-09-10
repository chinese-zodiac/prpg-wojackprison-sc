// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;
import {EnumerableSetAccessControlViewableAddress} from "./utils/EnumerableSetAccessControlViewableAddress.sol";
import {Authorizer} from "./Authorizer.sol";
import {IActionController} from "./interfaces/IActionController.sol";

//Anyone can be a registrar and add/del actions.
//TODO: Blacklisting, ability to remove blacklisted registrars
contract ActionControllerRegistry is Authorizer {
    mapping(address registrar => EnumerableSetAccessControlViewableAddress set)
        public registrarActionControllerSet;
    mapping(bytes32 acKey => IActionController ac) public actionControllers;
    mapping(address registrar => string ipfsCID)
        public registrarMetadataIpfsCID;

    EnumerableSetAccessControlViewableAddress public registrarSet;

    event BecomeRegistrar(address registrar);

    error AlreadyRegistrar(address registrar);
    error OnlyRegistrar(address registrar);
    error KeyAlreadyRegistered(bytes32 acKey);
    error AlreadyRegistered(IActionController actionController);
    error NotRegistered(IActionController actionController);
    error ActionControllerLacksKey(IActionController actionController);
    error ActionControllerKeyAlreadyRegistered(bytes32 acKey);

    modifier onlyRegistrar() {
        if (!registrarSet.getContains(msg.sender)) {
            revert OnlyRegistrar(msg.sender);
        }
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, address(this));
    }

    function becomeRegistrar() external {
        if (!registrarSet.getContains(msg.sender)) {
            registrarSet.add(msg.sender);
            EnumerableSetAccessControlViewableAddress set = new EnumerableSetAccessControlViewableAddress(
                    this
                );
            registrarActionControllerSet[msg.sender] = set;
            emit BecomeRegistrar(msg.sender);
        } else {
            revert AlreadyRegistrar(msg.sender);
        }
    }

    function setRegistrarMetadataIpfsCid(
        string calldata ipfsCID
    ) external onlyRegistrar {
        registrarMetadataIpfsCID[msg.sender] = ipfsCID;
    }

    function addActionController(IActionController _ac) external onlyRegistrar {
        EnumerableSetAccessControlViewableAddress acSet = registrarActionControllerSet[
                msg.sender
            ];
        if (acSet.getContains(address(_ac))) {
            revert AlreadyRegistered(_ac);
        }
        acSet.add(address(_ac));
        bytes32 acKey = _ac.AC_KEY();
        if (acKey == bytes32(0x0)) {
            revert ActionControllerLacksKey(_ac);
        }
        if (actionControllers[acKey] != IActionController(address(0x0))) {
            revert KeyAlreadyRegistered(acKey);
        }
        actionControllers[acKey] = _ac;
    }

    function removeActionController(
        IActionController _ac
    ) external onlyRegistrar {
        EnumerableSetAccessControlViewableAddress acSet = registrarActionControllerSet[
                msg.sender
            ];
        if (acSet.getContains(address(_ac))) {
            revert NotRegistered(_ac);
        }
        acSet.remove(address(_ac));
        delete actionControllers[_ac.AC_KEY()];
    }
}
