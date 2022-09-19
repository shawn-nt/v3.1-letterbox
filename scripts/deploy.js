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
  


};
  


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
