import { createAlchemyWeb3 } from "@alch/alchemy-web3";
import { exit } from "process";

const API_URL = process.env.API_URL;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const NFT_CONTRACT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS;
const TOKEN_CONTRACT_ADDRESS = process.env.TOKEN_CONTRACT_ADDRESS;

if (
  !API_URL ||
  !PUBLIC_KEY ||
  !PRIVATE_KEY ||
  !NFT_CONTRACT_ADDRESS ||
  !TOKEN_CONTRACT_ADDRESS
) {
  console.error("env is not set");
  exit();
}

const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/AimonToken.sol/AimonToken.json");
const tokenContract = new web3.eth.Contract(
  contract.abi,
  TOKEN_CONTRACT_ADDRESS
);

async function grantRole() {
  if (!API_URL || !PUBLIC_KEY || !PRIVATE_KEY) {
    console.error("env is not set");
    exit();
  }

  const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, "latest"); // get latest nonce

  const AIMON_NFT_ROLE = web3.utils.keccak256("AIMON_NFT_ROLE");

  const tx = {
    from: PUBLIC_KEY,
    to: TOKEN_CONTRACT_ADDRESS,
    nonce: nonce,
    gas: 500000,
    data: tokenContract.methods
      .grantRole(AIMON_NFT_ROLE, NFT_CONTRACT_ADDRESS)
      .encodeABI(),
  };

  const signedTx = await web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
  const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
  console.log(result.transactionHash);
  return result.transactionHash;
}

async function main() {
  await grantRole();
}

main();
