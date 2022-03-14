const hre = require("hardhat");

async function main() {
  const ICO = await hre.ethers.getContractFactory("ico");
  const Ico = await ICO.deploy(
    "0x23a235B543e969E33e9875C70027e821060428D3",1647252800,1647255800,1000,2000,5000
  );

  await Ico.deployed();

  console.log("Contract deployed to:", Ico.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  //0x95F191D72Ec9131D713a829955EB69aA8D3242Fd
  //https://rinkeby.etherscan.io/address/0x95F191D72Ec9131D713a829955EB69aA8D3242Fd#code

