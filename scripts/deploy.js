const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const headOfUpline = "0x51256F5459C1DdE0C794818AF42569030901a098";
  // const headOfUpline = "0x9Ee3Ee7184E55b92B52014B4cc0d421715fe6bf1";
  const tetherToken = "0xf2C6ccf7A9Bb5A768d29F93D09BF8A1c3b8235e6";
  // const tetherToken = "0x635417D99Fc0855A81CbFeb17E0271145d3cEcD9"; Goerli

  const binaryLandContract = await hre.ethers.deployContract(
    "Forex_Training_3",
    [tetherToken, headOfUpline]
  );

  await binaryLandContract.waitForDeployment();

  console.log("BinaryLand Contract Address:", binaryLandContract.target);

  await sleep(30 * 1000);

  await hre.run("verify:verify", {
    address: binaryLandContract.target,
    constructorArguments: [tetherToken, headOfUpline],
  });
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
