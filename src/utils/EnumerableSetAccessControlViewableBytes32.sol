// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.23;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IAuthorizer} from "../interfaces/IAuthorizer.sol";
import {Authorized} from "../Authorized.sol";

contract EnumerableSetAccessControlViewableBytes32 is Authorized {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set set;

    event Add(bytes32 data);
    event Remove(bytes32 data);

    error NotInSet(bytes32 data);

    constructor(IAuthorizer _authorizer) Authorized(_authorizer) {}

    function addMultiple(bytes32[] calldata _datas) external onlyManager {
        for (uint i; i < _datas.length; i++) {
            bytes32 data = _datas[i];
            if (!set.contains(data)) {
                set.add(data);
                emit Add(data);
            }
        }
    }

    function removeMultiple(bytes32[] calldata _datas) external onlyManager {
        for (uint i; i < _datas.length; i++) {
            bytes32 data = _datas[i];
            if (set.contains(data)) {
                set.remove(data);
                emit Remove(data);
            }
        }
    }

    function add(bytes32 _data) external onlyManager {
        if (!set.contains(_data)) {
            set.add(_data);
            emit Add(_data);
        }
    }

    function remove(bytes32 _data) external onlyManager {
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
