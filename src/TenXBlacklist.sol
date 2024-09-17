// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.23;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IterableArrayWithoutDuplicateKeys} from "./libs/IterableArrayWithoutDuplicateKeys.sol";

/*
Blacklisting is a serious decision that must only be made through
czodiac governance. Czodiac's community reserves the right to use its 
governance to blacklist any account and/or token for any reason at any time.
Legitimate reasons for blacklisting include but are not limited to:
- Presence on OFAC list
- CSAM
- formal request by US law enforcement
- money laundering
- hacking and/or exploiting dapps
- any other violations of czodiac's Terms of Use.
Czodiac's community cant guarantee that every bad guy or bad token is blacklisted.
So please contact czodiac governance if you have evidence of something bad.
Right now that would be t.me/czodiacofficial, if this is in the future and
thats not active then post publicly in whatever czodaic chat is most active.
*/
contract TenXBlacklistV2 is AccessControlEnumerable {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;

    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");

    IterableArrayWithoutDuplicateKeys.Map private accountBlacklist;

    error Blacklisted(address account);

    event BlacklistAdd(address account);
    event BlacklistDel(address account);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function revertIfAccountBlacklisted(address token) external view {
        if (isAccountBlacklisted(token)) {
            revert Blacklisted(token);
        }
    }

    function BLACKLISTER_addAccountBlacklist(
        address[] calldata accounts
    ) external onlyRole(BLACKLISTER_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            accountBlacklist.add(accounts[i]);
            emit BlacklistAdd(accounts[i]);
        }
    }

    function BLACKLISTER_delAccountBlacklist(
        address[] calldata accounts
    ) external onlyRole(BLACKLISTER_ROLE) {
        for (uint256 i = 0; i < accounts.length; i++) {
            accountBlacklist.remove(accounts[i]);
            emit BlacklistDel(accounts[i]);
        }
    }

    function accountBlacklistCount() external view returns (uint256) {
        return accountBlacklist.size();
    }

    function accountBlacklistAt(uint256 index) public view returns (address) {
        return accountBlacklist.getKeyAtIndex(index);
    }

    function isAccountBlacklisted(address account) public view returns (bool) {
        return accountBlacklist.getIndexOfKey(account) != -1;
    }
}
