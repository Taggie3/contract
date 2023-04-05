// eslint-disable-next-line @typescript-eslint/no-unused-vars
const hre = require('hardhat');
const { ethers, upgrades } = require('hardhat');
import * as fs from 'fs-extra';

export type DeployedContracts = {
  Brand3Slogan: string;
  Brand3Tag: string;
  RoyaltySplitter: string;
  Whitelist: string;
  Brand3Factory: string;
};

async function main() {
  let res: DeployedContracts = {
    Brand3Slogan: '',
    Brand3Tag: '',
    RoyaltySplitter: '',
    Whitelist: '',
    Brand3Factory: '',
  };

  let singers = await hre.ethers.getSigners();

  // WhiteLists
  const whitelistCount = 100;
  const whitelistContract = await hre.ethers.getContractFactory('Whitelist');
  const deployedWhitelistContractContract = await whitelistContract.deploy(whitelistCount);
  console.log('Whitelist Contract Address:', deployedWhitelistContractContract.address);

  const tagContract = await hre.ethers.getContractFactory('Brand3Tag');
  const deployedTagContract = await tagContract.deploy();
  console.log('Tag Contract Address:', deployedTagContract.address);

  const factoryContract = await hre.ethers.getContractFactory('Brand3Factory');
  const deployedFactoryContract = await factoryContract.deploy();
  console.log('Factory Contract Address:', deployedFactoryContract.address);

  // const metadataURI = "https://test_metadata.com";
  // const logoURI = "https://test_logo.com";
  // const signature = "0x123456"
  // const sloganName = "sloganName";
  // const sloganSymbol = "sloganSymbol";
  // const sloganContract = await hre.ethers.getContractFactory("Brand3Slogan");
  // const deployedSloganContract = await sloganContract.deploy(metadataURI, sloganName, sloganSymbol, logoURI);
  // console.log("Slogan Contract Address:", deployedSloganContract.address);

  const payees = [
    '0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106',
    '0x9c01bfc31C2D809b252422393e461dcaB841C8DA',
    '0x34A3704A224D0574aAe7fcAa049324Dc43a6d0b5',
  ];
  const shares = [40, 40, 20];
  const splitterContract = await hre.ethers.getContractFactory('RoyaltySplitter');
  const deployedSplitterContract = await splitterContract.deploy(payees, shares);
  console.log('Splitter Contract Address:', deployedSplitterContract.address);

  res.Brand3Factory = deployedFactoryContract.address;
  res.Brand3Tag = deployedTagContract.address;
  res.RoyaltySplitter = deployedSplitterContract.address;
  res.Whitelist = deployedWhitelistContractContract.address;

  fs.writeFileSync('./.env.json', JSON.stringify(res, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
