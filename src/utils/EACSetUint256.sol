// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.23;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EACSetUint256 is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet set;

    event Add(uint256 number);
    event Remove(uint256 number);

    error NotInSet(uint256 number);

    constructor() Ownable(msg.sender) {}

    function addMultiple(uint256[] calldata _numbers) external onlyOwner {
        for (uint i; i < _numbers.length; i++) {
            uint256 number = _numbers[i];
            if (!set.contains(number)) {
                set.add(number);
                emit Add(number);
            }
        }
    }

    function removeMultiple(uint256[] calldata _numbers) external onlyOwner {
        for (uint i; i < _numbers.length; i++) {
            uint256 number = _numbers[i];
            if (set.contains(number)) {
                set.remove(number);
                emit Remove(number);
            }
        }
    }

    function add(uint256 _number) external onlyOwner {
        if (!set.contains(_number)) {
            set.add(_number);
            emit Add(_number);
        }
    }

    function remove(uint256 _number) external onlyOwner {
        if (set.contains(_number)) {
            set.remove(_number);
            emit Remove(_number);
        }
    }

    function revertIfNotInSet(uint256 _number) external view {
        if (!set.contains(_number)) {
            revert NotInSet(_number);
        }
    }

    function getAll_HIGHGAS()
        external
        view
        returns (uint256[] memory numbers_)
    {
        numbers_ = set.values();
    }

    function getLength() external view returns (uint256 count_) {
        count_ = set.length();
    }

    function getAt(uint256 _index) external view returns (uint256 number_) {
        number_ = set.at(_index);
    }

    function getContains(
        uint256 _number
    ) external view returns (bool contains_) {
        contains_ = set.contains(_number);
    }
}
