// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./PokumonToken.sol";

contract PokumonNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct Status {
        string name;
        uint256 level;
        uint256 attack;
        uint256 defense;
        uint256 experience;
    }
    struct Pokumon {
        Status status;
        uint256 lastWalkTime;
        uint256 lastEatTime;
        bool wasChangedName;
    }
    // old variable before upgrade
    Status public status;
    uint256 public lastWalkTime;
    uint256 public lastEatTime;
    bool public wasChangedName;

    address tokenAddress;
    uint256 randNonce;
    mapping(uint256 => Pokumon) public pokumons;
    PokumonToken private pokumonToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("pokumon-ai", "PKMN");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        randNonce = 0;
    }

    function setPokumon(address tokenAddress) public onlyOwner {
        pokumonToken = PokumonToken(tokenAddress);
    }

    function initializePokumonForUpgrade(string memory name, uint256 tokenId) public onlyOwner {
        Status memory status = Status({
            name: name,
            level: 1,
            attack: 10,
            defense: 10,
            experience: 0
        });
        setPokumon(status, tokenId);
    }

    function setPokumon(Status memory status, uint256 tokenId) internal {
        pokumons[tokenId].lastWalkTime = block.timestamp;
        pokumons[tokenId].lastEatTime = block.timestamp;
        pokumons[tokenId].wasChangedName = false;
        pokumons[tokenId].status = status;
    }

    function safeMint(address to, string memory uri, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMintWithName(
        address to,
        string memory uri,
        string memory name
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        Status memory status = Status({
            name: name,
            level: 1,
            attack: 10,
            defense: 10,
            experience: 0
        });

        safeMint(to, uri, tokenId);
        setPokumon(status, tokenId);
    }

    function safeMintWithStatus(
        address to,
        string memory uri,
        string memory name,
        uint256 attack,
        uint256 defense
    ) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        Status memory status = Status({
            name: name,
            level: 1,
            attack: attack,
            defense: defense,
            experience: 0
        });

        safeMint(to, uri, tokenId);
        setPokumon(status, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function buy(uint256 _tokenId) public payable {
        require(msg.value >= 45);
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == owner());
        _transfer(nftOwner, msg.sender, _tokenId);
    }

    function setName(address wallet, string memory _name, uint256 _tokenId) public {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == owner());
        require(!pokumons[_tokenId].wasChangedName);
        require(pokumonToken.balanceOf(wallet) >= 100);
        pokumonToken.burn(wallet, 100);
        console.log("Changing name from '%s' to '%s'", pokumons[_tokenId].status.name, _name);
        pokumons[_tokenId].status.name = _name;
    }

    function walk(address wallet, uint256 _tokenId) public {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == owner());
        require(block.timestamp > pokumons[_tokenId].lastWalkTime + 8 hours);
        uint256 amount = 9 + randMod(3) * pokumons[_tokenId].status.level;
        pokumonToken.mint(wallet, amount);
        pokumons[_tokenId].lastWalkTime = block.timestamp;
    }

    function eat(address wallet, uint256 _tokenId) public {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == owner());
        require(block.timestamp > pokumons[_tokenId].lastEatTime + 3 hours);
        require(pokumons[_tokenId].status.level <= 100);
        require(pokumonToken.balanceOf(wallet) >= 10);

        pokumonToken.burn(wallet, 10);

        pokumons[_tokenId].status.experience += 30;
        if (pokumons[_tokenId].status.experience > 100 + 25 * (pokumons[_tokenId].status.level - 1) ) {
            pokumons[_tokenId].status.experience -= 100 + 25 * (pokumons[_tokenId].status.level - 1);
            pokumons[_tokenId].status.level += 1;
            pokumons[_tokenId].status.attack += randMod(10);
            pokumons[_tokenId].status.defense += randMod(10);
        }
        pokumons[_tokenId].lastEatTime = block.timestamp;
    }

    function randMod(uint256 _modulus) internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _modulus;
    }
}
