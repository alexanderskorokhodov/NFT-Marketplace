const hre = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("Deploying...")
  const Connector = await hre.ethers.getContractFactory("Connector")
  const connector = await Connector.deploy()
  await connector.deployed()
  console.log("Connector deployed to:", connector.address)
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarket");
  const nftMarketplace = await NFTMarketplace.deploy(connector.address);
  await nftMarketplace.deployed();
  console.log("Market deployed to:", nftMarketplace.address);

  fs.writeFileSync('./config.js', `
  export const marketAddress = '${nftMarketplace.address}'
  export const connectorAddress = '${connector.address}'
  `)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
