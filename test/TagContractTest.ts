import {Signer} from "ethers";

const {ethers, upgrades} = require("hardhat");

describe("TagContract", function () {
    it("tag mint test", async function () {

        // const TagContract = await ethers.getContractFactory('TagContract');
        // const tagContract = await upgrades.deployProxy(TagContract);
        // await tagContract.deployed();
        // console.log("tagContract deployed to:", tagContract.address);
        // const tagContractAddress = tagContract.address;
        //
        // await tagContract.mint('test', 'test', {gasLimit: 3000000});

        // const brandName = 'BrandName';
        // const brandSymbol = 'BrandSymbol';
        // const brandLogo = 'BrandLogo';
        // const brandSlogan = 'BrandSlogan';
        // const tags = [[0, 'test', 'test']];
        // const brandContractUri = 'metadata/contract/brand/1';
        // const BrandContract = await ethers.getContractFactory('BrandContract');
        // const brandContract = await upgrades.deployProxy(BrandContract,
        //     [brandName, brandSymbol, brandLogo, brandSlogan,  '0x1d27B2Fb12CF12fC9DEFE6B6dd1E2D58d5e8Ee01',tags,
        //         brandContractUri, '0xbF34748ed7b5b7Ab436666551c5BDD253fbF31F8']);
        // await brandContract.deployed();
        // console.log("brandContract deployed to:", brandContract.address);

        const provider = ethers.provider;
        const signer: Signer = await provider.getSigner();

        console.log(await signer.signMessage('BrandName'));
    });
});