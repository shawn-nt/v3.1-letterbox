// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { ContractType } = require("hardhat/internal/hardhat-network/stack-traces/model");
require('dotenv').config();
const { string } = require("hardhat/internal/core/params/argumentTypes");
const { BigNumber } = require("@ethersproject/bignumber");

async function main() {
  //console.log(process.env);
  process.env;
  const Contract = await hre.ethers.getContractFactory("LetterboxV3");
  const contract = await Contract.deploy("LetterboxV3", "LTRBOXv3");


  await contract.deployed();

  console.log("Contract deployed to: ", contract.address);
  
  
  // let tx = await contract.mintLetterbox(
  //   "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", // msg.sender
  //   "https://URLofLetterbox.com",
  //   "https://narrativetrails.xyz/letterboxURI/16", // what you got from Fleek.
  // );
  // console.log("minting letterbox...");
  // let receipt = await tx.wait();
  // let event = receipt.events.find(x => x.event === "LetterboxCreated");

  // console.log("letterbox token id: ", event.args.tokenId.toString());


  // tx = await contract.mintStamp("0x70997970C51812dc3A010C7d01b50e0d17dc79C8", "https://THISisAstamp/stamp.json");
  // receipt = await tx.wait();
  // event = receipt.events.find(x=> x.event === "StampCreated");
  // console.log("stamp token id: ", event.args.tokenId.toString() );

  
  // const result = await contract.getLetterboxFromURL("https://URLofLetterbox.com");
  // const {0: tokenMetadataURL, 1: tokenIdFromURL} = result;

  // console.log("letterbox id from url: ", tokenIdFromURL.toString());
  // console.log("letterbox URI from URL: ", tokenMetadataURL);

};
  


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
