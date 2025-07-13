import { ethers } from "hardhat";

async function main() {
  console.log("Deploying TicketMarketplace...");
  const marketplace = await ethers.getContractFactory("TicketMarketplace").then(f => f.deploy());
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();
  console.log(`✅ TicketMarketplace deployed to: ${marketplaceAddress}`);

  console.log("\nDeploying EventManager...");
  const eventManager = await ethers.getContractFactory("EventManager").then(f => f.deploy());
  await eventManager.waitForDeployment();
  const eventManagerAddress = await eventManager.getAddress();
  console.log(`✅ EventManager deployed to: ${eventManagerAddress}`);

  console.log("\nDeploying TicketBNPL...");
  const bnpl = await ethers.getContractFactory("TicketBNPL").then(f => f.deploy());
  await bnpl.waitForDeployment();
  const bnplAddress = await bnpl.getAddress();
  console.log(`✅ TicketBNPL deployed to: ${bnplAddress}`);
  
  console.log("\n🎉 Deployment complete! 🎉");
  console.log("---------------------------------");
  console.log("SAVE THESE ADDRESSES:");
  console.log(`MARKETPLACE_ADDRESS = "${marketplaceAddress}"`);
  console.log(`EVENT_MANAGER_ADDRESS = "${eventManagerAddress}"`);
  console.log(`BNPL_ADDRESS = "${bnplAddress}"`);
  console.log("---------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
