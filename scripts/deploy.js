const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const owner = "0x9Ee3Ee7184E55b92B52014B4cc0d421715fe6bf1"; // should change
  const tetherBEP20Token = "0x55d398326f99059fF775485246999027B3197955"; // tether bep20

  const binaryLandContract = await hre.ethers.deployContract(
    "Binary_Forex_Chain",
    [tetherBEP20Token, owner]
  );

  await binaryLandContract.waitForDeployment();

  console.log("BinaryLand Contract Address:", binaryLandContract.target);

  await sleep(30 * 1000);

  await hre.run("verify:verify", {
    address: binaryLandContract.target,
    constructorArguments: [tetherBEP20Token, owner],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
