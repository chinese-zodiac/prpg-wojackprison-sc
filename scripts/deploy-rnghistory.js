const hre = require("hardhat");
const loadJsonFile = require("load-json-file");

const { ethers } = hre;
const { parseEther } = ethers.utils;

async function main() {

    const RngHistory = await ethers.getContractFactory("RngHistory");
    const rngHistory = await RngHistory.deploy();
    await rngHistory.deployed();
    console.log("RngHistory deployed to:", rngHistory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
