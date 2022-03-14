const hre = require("hardhat");

async function main() {
  const ERC = await hre.ethers.getContractFactory("MyToken");
  const erc = await ERC.deploy();

  await erc.deployed();

  console.log("erc deployed to:", erc.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//0x23a235B543e969E33e9875C70027e821060428D3
//npx hardhat run scripts/ERC20.js --network rinkeby
//npx hardhat verify --contract "contracts/erc20.sol:MyToken"  --network rinkeby  0x23a235B543e969E33e9875C70027e821060428D3 
//verified link    https://rinkeby.etherscan.io/address/0x23a235B543e969E33e9875C70027e821060428D3#code
