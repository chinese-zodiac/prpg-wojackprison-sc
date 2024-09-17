// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IOptimismMintableERC20, ILegacyMintableERC20} from "./interfaces/IOptimismMintableERC20.sol";
import {TokenBase} from "./TokenBase.sol";
import "./presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmPair.sol";
import "./TenXBlacklist.sol";

//DEPLOYMENT INSTRUCTIONS
//Should use a unique deployer address that is only used for deploying and nothing else
//so that the nonce is the same on both chains.
//ADMIN should be a admin account, NOT deployer.
//Constructor params must be the same on both chains.
//Update settings with a admin account NOT deployer

//IMPORTANT WARNING:
//This contract implements methods that seem unecessary
//and are not in the inherited interfaces, but are
//actually part of undocumented interfaces that the optimism sdk requires.
//Newer dapps should not need these, but forks must implement.
contract TokenBaseOptimism is
    IOptimismMintableERC20,
    ILegacyMintableERC20,
    TokenBase
{
    /// @notice Address of the corresponding version of this token on the remote chain.
    address public immutable REMOTE_TOKEN;

    /// @notice Address of the StandardBridge on this network.
    address public immutable BRIDGE;

    /// @notice Emitted whenever tokens are minted for an account.
    /// @param account Address of the account tokens are being minted for.
    /// @param amount  Amount of tokens minted.
    event Mint(address indexed account, uint256 amount);

    /// @notice Emitted whenever tokens are burned from an account.
    /// @param account Address of the account tokens are being burned from.
    /// @param amount  Amount of tokens burned.
    event Burn(address indexed account, uint256 amount);

    /// @notice A modifier that only allows the bridge to call.
    modifier onlyBridge() {
        require(msg.sender == BRIDGE, "TBO: only bridge");
        _;
    }

    constructor(
        address admin,
        TenXBlacklistV2 _blacklist,
        string memory name,
        string memory ticker,
        uint256 _l1ChainID,
        uint256 _l2ChainID,
        address _l1Bridge, //l1 standard bridge address
        address _l2Bridge //l2 standard bridge address
    ) TokenBase(admin, _blacklist, name, ticker) {
        REMOTE_TOKEN = address(this);
        if (block.chainid == _l1ChainID) {
            BRIDGE = _l1Bridge;
        } else if (block.chainid == _l2ChainID) {
            BRIDGE = _l2Bridge;
        } else {
            require(false, "INVALID CHAIN");
        }
        _grantRole(MINTER_ROLE, BRIDGE);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @custom:legacy
    /// @notice Legacy getter for l1Token.
    function l1Token() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for REMOTE_TOKEN.
    function remoteToken() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for BRIDGE.
    function bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @custom:legacy
    /// @notice Legacy getter for BRIDGE.
    function l2Bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(
        bytes4 _interfaceId
    ) public pure virtual override(IERC165, AccessControl) returns (bool) {
        bytes4 iface1 = type(IERC165).interfaceId;
        // Interface corresponding to the updated OptimismMintableERC20 (this contract).
        bytes4 iface2 = type(IOptimismMintableERC20).interfaceId;
        return _interfaceId == iface1 || _interfaceId == iface2;
    }

    function mint(
        address to,
        uint256 amount
    )
        public
        override(
            IOptimismMintableERC20,
            ILegacyMintableERC20,
            ERC20PresetMinterPauser
        )
    {
        blacklist.revertIfAccountBlacklisted(to);
        ERC20PresetMinterPauser.mint(to, amount);
    }

    /// @notice Allows the StandardBridge on this network to burn tokens.
    /// @param _from   Address to burn tokens from.
    /// @param _amount Amount of tokens to burn.
    function burn(
        address _from,
        uint256 _amount
    )
        external
        virtual
        override(IOptimismMintableERC20, ILegacyMintableERC20)
        onlyBridge
    {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }
}
