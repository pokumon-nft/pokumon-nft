
import { createAlchemyWeb3 } from "@alch/alchemy-web3";
import { exit } from "process";

const API_URL = process.env.API_URL;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const NFT_CONTRACT_ADDRESS = process.env.NFT_CONTRACT_ADDRESS;
const TOKEN_CONTRACT_ADDRESS = process.env.TOKEN_CONTRACT_ADDRESS;

if (!API_URL) {
  console.error("env is not set");
  exit();
}

const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/AimonNFT.sol/AimonNFT.json");
const nftContract = new web3.eth.Contract(contract.abi, NFT_CONTRACT_ADDRESS);

async function setupNft(gas = 1000000, gasPrice = "500000000000") {
  if (!PUBLIC_KEY || !PRIVATE_KEY) {
    console.error("env is not set");
    exit();
  }
  const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, "latest"); // get latest nonce

  // the transaction
  const tx = {
    from: PUBLIC_KEY,
    to: NFT_CONTRACT_ADDRESS,
    nonce: nonce,
    gas,
    gasPrice,
    data: nftContract.methods
      .setAimon(TOKEN_CONTRACT_ADDRESS)
      .encodeABI(),
  };

  const signedTx = await web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
  const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
  console.log(result.transactionHash);
  return result.transactionHash;
}

function main() {
  const gas = 500000;
  const gasPrice = "200000000000";
  setupNft(gas, gasPrice);
}

main();
