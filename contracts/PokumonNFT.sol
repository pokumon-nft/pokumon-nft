// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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

    function setName(string memory _name) public {
        console.log("Changing name from '%s' to '%s'", status.name, _name);
        status.name = _name;
    }

    function getStatus() public view returns (Status memory) {
        return status;
    }

    function walk() public {
        require(block.timestamp > lastWalkTime + 8 hours);
        // get Token
    }

    function eat() public {
        require(block.timestamp > lastEatTime + 3 hours);
        require(status.level <= 100);
        // burn Token

        status.experience += 30;
        if (100 + 25 * (status.level - 1) > status.experience) {
            status.experience -= 100 + 25 * (status.level - 1);
            status.level += 1;
        }
    }
}
