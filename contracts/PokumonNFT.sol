// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./PokumonToken.sol";

contract PokumonNFT is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

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

    function initialize() public initializer {
        __ERC721_init("PokumonNFT", "PKM");
        __Ownable_init();
        __UUPSUpgradeable_init();

        lastWalkTime = block.timestamp;
        lastEatTime = block.timestamp;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setName(address my_address, string memory _name) public {
        require(!wasChangedName);
        PokumonToken token = PokumonToken(tokenAddress);
        require(token.balanceOf(my_address) >= 100);
        token.burn(my_address, 100);
        console.log("Changing name from '%s' to '%s'", status.name, _name);
        status.name = _name;
    }

    function getStatus() public view returns (Status memory) {
        return status;
    }

    function getLevel() public view returns (uint256) {
        return status.level;
    }

    function walk(address my_address) public {
        require(block.timestamp > lastWalkTime + 8 hours);
        PokumonToken token = PokumonToken(tokenAddress);
        token.mint(my_address);
        lastWalkTime = block.timestamp;
    }

    function eat(address my_address) public {
        require(block.timestamp > lastEatTime + 3 hours);
        require(status.level <= 100);
        PokumonToken token = PokumonToken(tokenAddress);
        require(token.balanceOf(my_address) >= 10);
        token.burn(my_address, 10);

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