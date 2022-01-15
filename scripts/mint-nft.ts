// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { createAlchemyWeb3 } from "@alch/alchemy-web3";
import { exit } from "process";

require("dotenv").config();
const API_URL = process.env.ROPSTEN_URL;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

if (!API_URL || !PUBLIC_KEY || !PRIVATE_KEY) {
  console.error("env is not set");
  process.exitCode = 1;
  exit();
}

const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/PokumonNFT.sol/PokumonNFT.json");
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Input NFT contract address
const nftContract = new web3.eth.Contract(contract.abi, contractAddress);

async function mintNFT(
  tokenURI: string,
  name: string,
  publicKey: string,
  privateKey: string
) {
  const nonce = await web3.eth.getTransactionCount(publicKey, "latest"); // get latest nonce

  // the transaction
  const tx = {
    from: PUBLIC_KEY,
    to: contractAddress,
    nonce: nonce,
    gas: 500000,
    data: nftContract.methods
      .safeMintWithName(PUBLIC_KEY, tokenURI, name)
      .encodeABI(),
  };

  const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
  const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
  console.log(result.transactionHash);
  return result.transactionHash;
}

module.exports = mintNFT;
mintNFT(
  "https://gateway.pinata.cloud/ipfs/QmNakDL3RXm2Q8AzVU8CX1KKHQvBE6VtzFsoN5oGDkUZz6",
  "Pikachu",
  PUBLIC_KEY,
  PRIVATE_KEY
);
