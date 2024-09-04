// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "./presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC20MetadataLogo.sol";
import "./libs/AmmLibrary.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmPair.sol";

contract TokenBase is ERC20PresetMinterPauser, IERC20MetadataLogo {
    using SafeERC20 for IERC20;
    mapping(address => bool) public isExempt;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string public logoUri;
    IAmmPair public ammCzusdPair;

    uint256 public buyBurnBps = 75;
    uint256 public sellBurnBps = 450;
    uint256 public maxBurnBps = 10000;

    event SetBurnBps(uint256 buyBurnBps, uint256 sellBurnBps);
    event SetIsExempt(address account, bool to);
    event SetLogoUri(string ipfsCid);
    event SetAmmPair(IAmmPair ammCzusdPair);
    event SetMaxBurnBps(uint256 maxBurnBps);

    constructor(
        address admin,
        string memory name,
        string memory ticker
    ) ERC20PresetMinterPauser(name, ticker, admin) {
        _grantRole(MANAGER_ROLE, admin);
        isExempt[address(0x0)] = true; //no tax for mints and burns
        emit SetBurnBps(buyBurnBps, sellBurnBps);
        emit SetIsExempt(address(0x0), true);
        emit SetMaxBurnBps(maxBurnBps);
    }

    function _update(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        //Handle burn
        if (
            //No tax for exempt
            isExempt[sender] ||
            isExempt[recipient] ||
            //No tax if not a trade
            (sender != address(ammCzusdPair) &&
                recipient != address(ammCzusdPair))
        ) {
            super._update(sender, recipient, amount);
        } else {
            uint256 totalBurnFee;
            //sell fee
            if (recipient == address(ammCzusdPair)) {
                totalBurnFee += (amount * sellBurnBps) / 10000;
            }
            //buy fee
            if (sender == address(ammCzusdPair)) {
                totalBurnFee += (amount * buyBurnBps) / 10000;
            }
            if (totalBurnFee > 0) super._burn(sender, totalBurnFee);
            super._update(sender, recipient, amount - totalBurnFee);
        }
    }

    function setBurnBps(
        uint256 _onBuy,
        uint256 _onSell
    ) public onlyRole(MANAGER_ROLE) {
        buyBurnBps = _onBuy;
        sellBurnBps = _onSell;
        emit SetBurnBps(buyBurnBps, sellBurnBps);
    }

    function setIsExempt(address _for, bool _to) public onlyRole(MANAGER_ROLE) {
        isExempt[_for] = _to;
    }

    function setLogoUri(
        string calldata ipfsCid
    ) external onlyRole(MANAGER_ROLE) {
        logoUri = string.concat("ipfs://", ipfsCid);
        emit SetLogoUri(ipfsCid);
    }

    function spawnAmmPair(
        IAmmFactory _factory,
        IERC20 _czusd
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(ammCzusdPair) == address(0x0), "Pair already spawned");
        ammCzusdPair = IAmmPair(
            _factory.createPair(address(this), address(_czusd))
        );
        emit SetAmmPair(ammCzusdPair);
    }

    function setAmmPair(IAmmPair _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ammCzusdPair = _to;
        emit SetAmmPair(ammCzusdPair);
    }

    function setMaxBurnBps(uint256 _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxBurnBps = _to;
        emit SetMaxBurnBps(maxBurnBps);
    }

    function recoverERC20(
        address tokenAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).safeTransfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }
}
