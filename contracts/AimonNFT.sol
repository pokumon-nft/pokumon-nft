// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./AimonToken.sol";

contract AimonNFT is
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
    struct Aimon {
        Status status;
        uint256 lastWalkTime;
        uint256 lastEatTime;
        bool wasChangedName;
    }

    address tokenAddress;
    uint256 randNonce;
    mapping(uint256 => Aimon) public aimons;
    AimonToken private aimonToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("ai-monsters", "AIMN");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        randNonce = 0;
    }

    function setAimon(address tokenAddress) public onlyOwner {
        aimonToken = AimonToken(tokenAddress);
    }

    function initializeAimonForUpgrade(string memory name, uint256 tokenId) public onlyOwner {
        Status memory status = Status({
            name: name,
            level: 1,
            attack: 10,
            defense: 10,
            experience: 0
        });
        setAimon(status, tokenId);
    }

    function setAimon(Status memory status, uint256 tokenId) internal {
        aimons[tokenId].lastWalkTime = block.timestamp;
        aimons[tokenId].lastEatTime = block.timestamp;
        aimons[tokenId].wasChangedName = false;
        aimons[tokenId].status = status;
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
        setAimon(status, tokenId);
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
        setAimon(status, tokenId);
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
        require(nftOwner == msg.sender);
        _transfer(nftOwner, msg.sender, _tokenId);
    }

    function setName(address wallet, string memory _name, uint256 _tokenId) public {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == msg.sender);
        require(!aimons[_tokenId].wasChangedName);
        require(aimonToken.balanceOf(wallet) >= 100);
        aimonToken.burn(wallet, 100);
        console.log("Changing name from '%s' to '%s'", aimons[_tokenId].status.name, _name);
        aimons[_tokenId].status.name = _name;
    }

    function walk(address wallet, uint256 _tokenId) public {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == msg.sender);
        require(block.timestamp > aimons[_tokenId].lastWalkTime + 2 hours);
        uint256 amount = 9 + randMod(3) * aimons[_tokenId].status.level;
        aimonToken.mint(wallet, amount);
        aimons[_tokenId].lastWalkTime = block.timestamp;
    }

    function eat(address wallet, uint256 _tokenId) public {
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == msg.sender);
        require(block.timestamp > aimons[_tokenId].lastEatTime + 2 hours);
        require(aimons[_tokenId].status.level <= 100);
        require(aimonToken.balanceOf(wallet) >= 10);

        aimonToken.burn(wallet, 10);

        aimons[_tokenId].status.experience += 30;
        if (aimons[_tokenId].status.experience > 100 + 25 * (aimons[_tokenId].status.level - 1) ) {
            aimons[_tokenId].status.experience -= 100 + 25 * (aimons[_tokenId].status.level - 1);
            aimons[_tokenId].status.level += 1;
            aimons[_tokenId].status.attack += randMod(10);
            aimons[_tokenId].status.defense += randMod(10);
        }
        aimons[_tokenId].lastEatTime = block.timestamp;
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
