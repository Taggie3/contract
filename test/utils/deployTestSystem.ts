import { Signer } from 'ethers';
import hre, { ethers } from 'hardhat';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { upgrades } = require('hardhat');
import {
  Brand3Slogan,
  Brand3Factory,
  Brand3Tag,
  RoyaltySplitter,
  Whitelist, Brand3Factory__factory
} from '../../typechain-types';

export type TestSystemContractsType = {
  brand3Slogan: Brand3Slogan;
  brand3Factory: Brand3Factory;
  brand3Tag: Brand3Tag;
  royaltySplitter: RoyaltySplitter;
  whitelist: Whitelist;
};

export async function deployTestContracts(
  deployer: Signer,
): Promise<TestSystemContractsType> {
  // Deploy mocked contracts

  // Deploy real contracts
  const _brand3Tag = await ethers.getContractFactory("Brand3Tag");
  const brand3Tag = await _brand3Tag.connect(deployer).deploy();

  const _brand3Slogan = await ethers.getContractFactory('Brand3Slogan');
  const brand3Slogan = await _brand3Slogan.connect(deployer).deploy(
    "https://brand3Slogan.com",
    "IT MAKES SMART CONTRACT SAFU",
    "IMSCS",
    "https://brand3Logo.com"
  );

  const _brand3Factory = await ethers.getContractFactory('Brand3Factory');
  const brand3Factory = await _brand3Factory.connect(deployer).deploy();

  // define the payees and shares
  const payees = [
    "0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106",
    "0x9c01bfc31C2D809b252422393e461dcaB841C8DA",
    "0x34A3704A224D0574aAe7fcAa049324Dc43a6d0b5"
  ];
  const shares = [40, 40, 20];
  const _royaltySplitter = await ethers.getContractFactory('RoyaltySplitter');
  const royaltySplitter =  await _royaltySplitter.connect(deployer).deploy(
    payees,
    shares
  )

  const whitelistCount = 100;
  const _whitelist = await ethers.getContractFactory('Whitelist');
  const whitelist = await _whitelist.connect(deployer).deploy(whitelistCount)

  return {
    brand3Slogan,
    brand3Factory,
    brand3Tag,
    royaltySplitter,
    whitelist
  };
}

export async function initTestSystem(
  c: TestSystemContractsType
) {}

export async function deployTestSystem(
  deployer: Signer,
): Promise<TestSystemContractsType> {
  const c = await deployTestContracts(deployer);
  const deployerAddress = await deployer.getAddress();
  await initTestSystem(c);
  return c;
}
