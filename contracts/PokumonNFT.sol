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
    Status public status;
    uint256 public lastWalkTime;
    uint256 public lastEatTime;
    bool public wasChangedName = false;
    address tokenAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    uint256 randNonce = 0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC721_init("PokumonNFT", "PKMN");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        lastWalkTime = block.timestamp;
        lastEatTime = block.timestamp;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMintWithName(
        address to,
        string memory uri,
        string memory name
    ) public onlyOwner {
        safeMint(to, uri);
        status = Status({
            name: name,
            level: 1,
            attack: 10,
            defense: 10,
            experience: 0
        });
    }

    function safeMintWithStatus(
        address to,
        string memory uri,
        string memory name,
        uint256 attack,
        uint256 defense
    ) public onlyOwner {
        safeMint(to, uri);
        status = Status({
            name: name,
            level: 1,
            attack: attack,
            defense: defense,
            experience: 0
        });
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

    function buy(uint256 _tokenId) payable public {
        require(msg.value >= 45);
        address nftOwner = ownerOf(_tokenId);
        require(nftOwner == owner());
        _transfer(nftOwner, msg.sender, _tokenId);
    }

    function setName(address wallet, string memory _name) public onlyOwner {
        require(!wasChangedName);
        PokumonToken token = PokumonToken(tokenAddress);
        require(token.balanceOf(wallet) >= 100);
        token.burn(wallet, 100);
        console.log("Changing name from '%s' to '%s'", status.name, _name);
        status.name = _name;
    }

    function getStatus() public view returns (Status memory) {
        return status;
    }

    function getLevel() public view returns (uint256) {
        return status.level;
    }

    function walk(address wallet) public onlyOwner {
        require(block.timestamp > lastWalkTime + 8 hours);
        PokumonToken token = PokumonToken(tokenAddress);
        token.mint(wallet);
        lastWalkTime = block.timestamp;
    }

    function eat(address wallet) public onlyOwner {
        require(block.timestamp > lastEatTime + 3 hours);
        require(status.level <= 100);
        PokumonToken token = PokumonToken(tokenAddress);
        require(token.balanceOf(wallet) >= 10);

        token.burn(wallet, 10);

        status.experience += 30;
        if (100 + 25 * (status.level - 1) > status.experience) {
            status.experience -= 100 + 25 * (status.level - 1);
            status.level += 1;
            status.attack += randMod(10);
            status.defense += randMod(10);
        }
        lastEatTime = block.timestamp;
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
