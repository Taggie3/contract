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
    let res: DeployedContracts = {
        BrandUtil: '',
        BrandSetContract: '',
        BrandContract: '',
        IPContract: '',
        TagContract: '',
    };

    const registerAddress = "0x02101dfB77FDE026414827Fdc604ddAF224F0921";
    const accountImplement = "0x2d25602551487c3f3354dd80d76d54383a243358";
    const chainId = 80001;
    const salt = 3;
    const BrandUtil = await ethers.getContractFactory('BrandUtil');
    const brandUtil = await upgrades.deployProxy(BrandUtil, [registerAddress, accountImplement, chainId, salt]);
    await brandUtil.deployed();
    console.log("brandUtil deployed to:", brandUtil.address);
    const brandUtilAddress = brandUtil.address;

    const TagContract = await ethers.getContractFactory('TagContract');
    const tagContract = await upgrades.deployProxy(TagContract);
    await tagContract.deployed();
    console.log("tagContract deployed to:", tagContract.address);
    const tagContractAddress = tagContract.address;

    await tagContract.mint('test', 'test');

    const brandSetContractUri = SERVER_HOST + 'metadata/contract/brandSet';
    const BrandSetContract = await ethers.getContractFactory('BrandSetContract');
    const brandSetContract = await upgrades.deployProxy(BrandSetContract,
        [tagContractAddress, brandSetContractUri, brandUtilAddress]);
    await brandSetContract.deployed();
    console.log("brandSetContract deployed to:", brandSetContract.address);
    const brandSetAddress = brandSetContract.address;

    const brandName = 'BrandName';
    const brandSymbol = 'BrandSymbol';
    const brandLogo = 'BrandLogo';
    const brandSlogan = 'BrandSlogan';
    const tags = [[0, 'test', 'test']];
    const brandContractUri = SERVER_HOST + '/metadata/contract/brand/1';
    const BrandContract = await ethers.getContractFactory('BrandContract');
    const brandContract = await upgrades.deployProxy(BrandContract,
        [brandName, brandSymbol, brandLogo, brandSlogan, brandSetAddress, tags, brandContractUri, brandUtilAddress]);
    await brandContract.deployed();
    console.log("brandContract deployed to:", brandContract.address);
    const brandAddress = brandContract.address;

    const provider = ethers.provider;
    const signer: Signer = await provider.getSigner();

    const signature = await signer.signMessage(brandName);
    // console.log(signature);
    const response = await brandSetContract.mint('test', signature, brandAddress);
    // console.log(response);

    const ipName = 'IPName';
    const ipSymbol = 'IPSymbol';
    const ipLogo = 'IPLogo';
    // const creator = '0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106';
    const ipContractUri = SERVER_HOST + '/metadata/contract/ip/1';
    const IPContract = await ethers.getContractFactory('IPContract');
    const ipContract = await upgrades.deployProxy(IPContract,
        [ipName, ipSymbol, ipLogo, brandAddress, ipContractUri, brandUtilAddress]);
    await ipContract.deployed();
    console.log("ipContract deployed to:", ipContract.address);

    await brandContract.mint('test', ipContract.address);


    res.BrandUtil = brandUtilAddress
    res.BrandSetContract = brandSetAddress
    res.BrandContract = brandAddress
    res.IPContract = ipContract.address
    res.TagContract = tagContractAddress

    fs.writeFileSync('./deployedContract.json', JSON.stringify(res, null, 2));
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

//npx hardhat run .\scripts\deploy.ts --network mumbai