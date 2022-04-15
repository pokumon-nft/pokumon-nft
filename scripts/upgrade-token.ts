import { ethers, upgrades } from "hardhat";
import { exit } from "process";

const TOKEN_CONTRACT_ADDRESS = process.env.TOKEN_CONTRACT_ADDRESS;
const PUBLIC_KEY = process.env.PUBLIC_KEY;

async function main() {
  if (!PUBLIC_KEY || !TOKEN_CONTRACT_ADDRESS) {
    console.error("env is not set");
    exit();
  }

  // ローカルで動かす際はgetContractFactoryの第二引数にownerを指定
  const AimonToken = await ethers.getContractFactory("AimonToken");
  const token = await upgrades.upgradeProxy(
    TOKEN_CONTRACT_ADDRESS,
    AimonToken
  );

  await token.deployed();

  console.log("Token deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

