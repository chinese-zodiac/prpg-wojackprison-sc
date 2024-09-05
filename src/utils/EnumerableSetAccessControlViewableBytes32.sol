// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.23;
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract EnumerableSetAccessControlViewableBytes32 is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    EnumerableSet.Bytes32Set set;

    event Add(bytes32 data);
    event Remove(bytes32 data);

    error NotInSet(bytes32 data);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addMultiple(
        bytes32[] calldata _datas
    ) external onlyRole(MANAGER_ROLE) {
        for (uint i; i < _datas.length; i++) {
            bytes32 data = _datas[i];
            if (!set.contains(data)) {
                set.add(data);
                emit Add(data);
            }
        }
    }

    function removeMultiple(
        bytes32[] calldata _datas
    ) external onlyRole(MANAGER_ROLE) {
        for (uint i; i < _datas.length; i++) {
            bytes32 data = _datas[i];
            if (set.contains(data)) {
                set.remove(data);
                emit Remove(data);
            }
        }
    }

    function add(bytes32 _data) external onlyRole(MANAGER_ROLE) {
        if (!set.contains(_data)) {
            set.add(_data);
            emit Add(_data);
        }
    }

    function remove(bytes32 _data) external onlyRole(MANAGER_ROLE) {
        if (set.contains(_data)) {
            set.remove(_data);
            emit Remove(_data);
        }
    }

    function revertIfNotInSet(bytes32 _data) external view {
        if (!set.contains(_data)) {
            revert NotInSet(_data);
        }
    }

    function getAll_HIGHGAS() external view returns (bytes32[] memory datas_) {
        datas_ = set.values();
    }

    function getLength() external view returns (uint256 count_) {
        count_ = set.length();
    }

    function getAt(uint256 _index) external view returns (bytes32 data_) {
        data_ = set.at(_index);
    }

    function getContains(bytes32 _data) external view returns (bool contains_) {
        contains_ = set.contains(_data);
    }
}
