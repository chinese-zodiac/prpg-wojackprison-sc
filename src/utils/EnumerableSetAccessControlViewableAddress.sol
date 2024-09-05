// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.23;
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract EnumerableSetAccessControlViewableAddress is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    EnumerableSet.AddressSet set;

    event Add(address account);
    event Remove(address account);

    error NotInSet(address account);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addMultiple(
        address[] calldata _accounts
    ) external onlyRole(MANAGER_ROLE) {
        for (uint i; i < _accounts.length; i++) {
            address account = _accounts[i];
            if (!set.contains(account)) {
                set.add(account);
                emit Add(account);
            }
        }
    }

    function removeMultiple(
        address[] calldata _accounts
    ) external onlyRole(MANAGER_ROLE) {
        for (uint i; i < _accounts.length; i++) {
            address account = _accounts[i];
            if (set.contains(account)) {
                set.remove(account);
                emit Remove(account);
            }
        }
    }

    function add(address _account) external onlyRole(MANAGER_ROLE) {
        if (!set.contains(_account)) {
            set.add(_account);
            emit Add(_account);
        }
    }

    function remove(address _account) external onlyRole(MANAGER_ROLE) {
        if (set.contains(_account)) {
            set.remove(_account);
            emit Remove(_account);
        }
    }

    function revertIfNotInSet(address _account) external view {
        if (!set.contains(_account)) {
            revert NotInSet(_account);
        }
    }

    function getAll_HIGHGAS()
        external
        view
        returns (address[] memory accounts_)
    {
        accounts_ = set.values();
    }

    function getLength() external view returns (uint256 count_) {
        count_ = set.length();
    }

    function getAt(uint256 _index) external view returns (address account_) {
        account_ = set.at(_index);
    }

    function getContains(
        address _account
    ) external view returns (bool contains_) {
        contains_ = set.contains(_account);
    }
}
