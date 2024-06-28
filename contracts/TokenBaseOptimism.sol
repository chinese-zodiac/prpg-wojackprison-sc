// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IOptimismMintableERC20} from "./interfaces/IOptimismMintableERC20.sol";
import {TokenBase} from "./TokenBase.sol";
import "./presets/ERC20PresetMinterPauser.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmPair.sol";

contract TokenBaseOptimism is IOptimismMintableERC20, TokenBase {
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
        require(
            msg.sender == BRIDGE,
            "MyCustomL2Token: only bridge can mint and burn"
        );
        _;
    }

    constructor(
        address admin,
        string memory name,
        string memory ticker,
        address _bridge //l2 standard bridge address
    ) TokenBase(admin, name, ticker) {
        _grantRole(MANAGER_ROLE, admin);

        REMOTE_TOKEN = address(this);
        BRIDGE = _bridge;
        _grantRole(MINTER_ROLE, _bridge);
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
    ) public override(IOptimismMintableERC20, ERC20PresetMinterPauser) {
        ERC20PresetMinterPauser.mint(to, amount);
    }

    /// @notice Allows the StandardBridge on this network to burn tokens.
    /// @param _from   Address to burn tokens from.
    /// @param _amount Amount of tokens to burn.
    function burn(
        address _from,
        uint256 _amount
    ) external virtual override(IOptimismMintableERC20) onlyBridge {
        _burn(_from, _amount);
        emit Burn(_from, _amount);
    }
}
