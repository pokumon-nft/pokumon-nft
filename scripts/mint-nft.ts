// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { createAlchemyWeb3 } from "@alch/alchemy-web3";
import { exit } from "process";

require("dotenv").config();
const API_URL = process.env.API_URL;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

if (!API_URL || !PUBLIC_KEY || !PRIVATE_KEY) {
  console.error("env is not set");
  process.exitCode = 1;
  exit();
}

const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/PokumonNFT.sol/PokumonNFT.json");
const contractAddress = "0x5c68371a863849e66dcac8d83b6d89b0437ef177"; // Input NFT contract address
const nftContract = new web3.eth.Contract(contract.abi, contractAddress);

async function mintNFT(
  tokenURI: string,
  publicKey: string,
  privateKey: string
) {
  const nonce = await web3.eth.getTransactionCount(publicKey, "latest"); // get latest nonce
  const dummyTokenId = 1234;

  // the transaction
  const tx = {
    from: PUBLIC_KEY,
    to: contractAddress,
    nonce: nonce,
    gas: 500000,
    data: nftContract.methods.safeMint(PUBLIC_KEY, dummyTokenId).encodeABI(),
  };

  const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
  const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
  console.log(result.transactionHash);
  return result.transactionHash;
}

module.exports = mintNFT;
mintNFT(
  "https://gateway.pinata.cloud/ipfs/QmNakDL3RXm2Q8AzVU8CX1KKHQvBE6VtzFsoN5oGDkUZz6",
  PUBLIC_KEY,
  PRIVATE_KEY
);
