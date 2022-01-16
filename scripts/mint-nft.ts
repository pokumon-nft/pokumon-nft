// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { createAlchemyWeb3 } from "@alch/alchemy-web3";
import { exit } from "process";
import { NFTStorage, File } from "nft.storage";
import path from "path";
import fs from "fs";

require("dotenv").config();
const API_URL = process.env.ROPSTEN_URL!;
const PUBLIC_KEY = process.env.PUBLIC_KEY!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const NFTSTORAGE_API_KEY = process.env.NFTSTORAGE_API_KEY!;

if (!API_URL || !PUBLIC_KEY || !PRIVATE_KEY || !NFTSTORAGE_API_KEY) {
  console.error("env is not set");
  exit();
}

const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/PokumonNFT.sol/PokumonNFT.json");
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Input NFT contract address
const nftContract = new web3.eth.Contract(contract.abi, contractAddress);
const storageClient = new NFTStorage({ token: "API_TOKEN" });

async function uploadIPFS(filePath: string, name: string, description: string) {
  const imageData = await fs.readFileSync(filePath, "binary");
  const fileName = path.basename(filePath);
  const metadata = await storageClient.store({
    name: name,
    description: description,
    image: new File([imageData], fileName, {
      type: "image/jpg",
    }),
  });
  console.log(metadata.url);
  return metadata.url;
  // ipfs://bafyreib4pff766vhpbxbhjbqqnsh5emeznvujayjj4z2iu533cprgbz23m/metadata.json
}

async function mintNFT(tokenURI: string, name: string) {
  const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, "latest"); // get latest nonce

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

  const signedTx = await web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
  const result = await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
  console.log(result.transactionHash);
  return result.transactionHash;
}

async function main() {
  const namesFile = fs.readFileSync("../ai_models/pokumon_names.txt", "utf8");
  const names = namesFile.toString().split("\n");
  for (let i = 0; i < 10; i++) {
    const name = names[i];
    const description = "";
    const filePath = "../ai_models/images/" + i + ".jpg";
    const tokenURI = await uploadIPFS(filePath, name, description);
    mintNFT(tokenURI, name);
  }
}

main();
