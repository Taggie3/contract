// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Signer} from "ethers";

const {ethers, upgrades} = require("hardhat");
import * as fs from 'fs-extra';

require("dotenv").config({path: ".env"});

const SERVER_HOST = process.env.SERVER_HOST;
const GAS_LIMIT = 3000000;

export type DeployedContracts = {
    BrandUtil: string;
    BrandSetContract: string;
    BrandContract: string;
    IPContract: string;
    TagContract: string;
};

async function main() {

    const jsonString = fs.readFileSync('./deployedContract.json', 'utf8');
    const deployedContracts = JSON.parse(jsonString) as DeployedContracts;
    console.log(deployedContracts);

    const BrandUtil = await ethers.getContractFactory('BrandUtil');
    const brandUtil = await upgrades.upgradeProxy(deployedContracts.BrandUtil, BrandUtil);
    // console.log(brandUtil);
    const BrandSetContract = await ethers.getContractFactory('BrandSetContract');
    const brandSetContract = await upgrades.upgradeProxy(deployedContracts.BrandSetContract, BrandSetContract);
    // console.log(brandSetContract);
    const BrandContract = await ethers.getContractFactory('BrandContract');
    const brandContract = await upgrades.upgradeProxy(deployedContracts.BrandContract, BrandContract);
    // console.log(brandContract);
    const IPContract = await ethers.getContractFactory('IPContract');
    const ipContract = await upgrades.upgradeProxy(deployedContracts.IPContract, IPContract);
    // console.log(ipContract);
    const TagContract = await ethers.getContractFactory('TagContract');
    const tagContract = await upgrades.upgradeProxy(deployedContracts.TagContract, TagContract);
    // console.log(tagContract);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

//npx hardhat run .\scripts\upgrade.ts --network mumbai