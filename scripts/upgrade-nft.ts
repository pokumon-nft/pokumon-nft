import { ethers, upgrades } from "hardhat";
import { exit } from "process";

const NFT_CONTRACT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS;
const PUBLIC_KEY = process.env.PUBLIC_KEY;

async function main() {
  if (!PUBLIC_KEY || !NFT_CONTRACT_ADDRESS) {
    console.error("env is not set");
    exit();
  }

  // ローカルで動かす際はgetContractFactoryの第二引数にownerを指定
  const AimonNFT = await ethers.getContractFactory("AimonNFT");
  const token = await upgrades.upgradeProxy(NFT_CONTRACT_ADDRESS, AimonNFT);

  await token.deployed();

  console.log("Token deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
