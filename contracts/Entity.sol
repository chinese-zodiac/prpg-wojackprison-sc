// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19;

import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./libs/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IEntity.sol";
import "./interfaces/ILocation.sol";
import "./interfaces/ILocationController.sol";

contract Entity is
    IEntity,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    ILocationController public locationController;

    // for nft gen requiring randomness
    mapping(uint256 id => bytes32 seed) public seed;
    // for type data, when different nft sets on same contract
    // use different algos for determining image from id
    mapping(uint256 id => bytes32 eType) public eType;

    constructor(
        string memory name,
        string memory symbol,
        ILocationController _locationController
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        locationController = _locationController;
    }

    function _mint(
        address _to,
        ILocation _location,
        bytes32 _randWord,
        bytes32 _eType
    ) internal virtual returns (uint256 id_) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "JNT: must have manager role to mint"
        );

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 newTokenId = _tokenIdTracker.current();
        _mint(address(this), newTokenId);

        //set location
        locationController.spawn(this, newTokenId, _location);

        //set seed
        seed[newTokenId] = _randWord;
        //set entity type
        eType[newTokenId] = _eType;

        //transfer to minter
        _transfer(address(this), _to, newTokenId);

        _tokenIdTracker.increment();

        return newTokenId;
    }

    function burn(
        uint256 _nftId
    ) public virtual override(IEntity, ERC721Burnable) {
        //unregister location
        locationController.despawn(this, _nftId);
        ERC721Burnable.burn(_nftId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721Enumerable, ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _increaseBalance(
        address account,
        uint128 amount
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, amount);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return ERC721Enumerable._update(to, tokenId, auth);
    }
}
