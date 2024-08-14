// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// Is theoreticaly exploitable by a malicious miner
// any contract using this should have an admin able to switch
// the RNG to an upgraded version that has security guarantees

pragma solidity >=0.8.19;

import "./libs/Counters.sol";

contract CheapRNG {
    using Counters for Counters.Counter;
    Counters.Counter private _requestIDTracker;

    mapping(uint256 ID => uint256 blockNumber) public blockNumber;
    mapping(uint256 ID => address requester) public requesters;

    event RequestRandom(uint256 requestID);
    event FullfillRandom(uint256 requestID, bytes32 randWord);

    constructor() {
        // start at 1
        _requestIDTracker.increment();
    }

    function requestRandom() public returns (uint256 requestID) {
        requestID = _requestIDTracker.current();
        _requestIDTracker.increment();
        blockNumber[requestID] = block.number + 1;
        requesters[requestID] = msg.sender;
        emit RequestRandom(requestID);
    }

    function fullfillRandom(
        uint256 requestID
    ) public returns (bytes32 randWord) {
        address requester = requesters[requestID];
        require(msg.sender == requester, "RNG: Not requester");
        randWord = keccak256(
            abi.encodePacked(
                //blockHash for randomness source.
                blockhash(blockNumber[requestID]),
                //Contract address for contract unique result.
                address(this),
                //requestID for request unique result.
                requestID
            )
        );
        delete blockNumber[requestID];
        delete requesters[requestID];
        emit FullfillRandom(requestID, randWord);
    }
}
