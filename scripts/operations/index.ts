import * as readline from 'readline';
import hre, { ethers } from 'hardhat';
import { toBN } from '../util/web3utils';
import inquirer from 'inquirer';
import * as dotenv from 'dotenv';
import chalk from 'chalk';
import * as fs from 'fs-extra';
import { DeployedContracts } from '../deploy';
import { Signer } from 'ethers';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function question(query: string) {
  return new Promise(resolve => rl.question(query, answ => resolve(answ)));
}

function operation(query: string) {
  return new Promise(resolve => rl.question(query, answ => resolve(answ)));
}

function send(method: string, params?: Array<any>) {
  return hre.ethers.provider.send(method, params === undefined ? [] : params);
}

function mineBlock() {
  return send('evm_mine', []);
}

async function fastForward(seconds: number) {
  const method = 'evm_increaseTime';
  const params = [seconds];
  await send(method, params);
  await mineBlock();
}

async function currentTime() {
  const { timestamp } = await ethers.provider.getBlock('latest');
  return timestamp;
}

async function availableAddresses() {
  const signers = await hre.ethers.getSigners();
  const addresses = [];
  for (let i = 0; i < signers.length; i++) {
    addresses.push(await signers[i].getAddress());
  }
  return addresses;
}

async function main() {
  const prompt = inquirer.createPromptModule();
  let res: DeployedContracts = {} as DeployedContracts;
  if (fs.existsSync('./.env.json')) {
    res = JSON.parse(fs.readFileSync('./.env.json', 'utf8'));
  } else {
    throw new Error('No .env.json file found');
  }

  const signers = await hre.ethers.getSigners();

  const _brand3Factory = await hre.ethers.getContractFactory('Brand3Factory');
  const brand3Factory = await _brand3Factory.attach(res.Brand3Factory);

  const _brand3Tag = await hre.ethers.getContractFactory('Brand3Tag');
  const brand3Tag = await _brand3Tag.attach(res.Brand3Tag);

  const _RoyaltySplitter = await hre.ethers.getContractFactory('RoyaltySplitter');
  const RoyaltySplitter = await _RoyaltySplitter.attach(res.RoyaltySplitter);

  const _whitelist = await hre.ethers.getContractFactory('Whitelist');
  const whitelist = await _whitelist.attach(res.Whitelist);

  let currentSigner = await signers[0];
  const choices = ['Create a New Brand', 'Get Brand Owner', 'Get Brand3 Slogan', 'Exit', 'Create a New NFT'];

  while (true) {
    const answers = await prompt({
      type: 'list',
      name: 'operation',
      message: 'What do you want to do?',
      choices,
    });
    switch (answers.operation) {
      case 'Create a New NFT':
        const brand3SloganAddress = await prompt([
          {
            type: 'input',
            name: 'address',
            message: 'Enter the brand3Slogan address',
          }
        ]);
        const creatorAddress = await prompt([
          {
            type: 'input',
            name: 'address',
            message: 'Enter the creator address',
          }
        ]);
        const splitterAddress = await prompt([
          {
            type: 'input',
            name: 'address',
            message: 'Enter the splitter address',
          }
        ]);
        const _brand3Slogan = await hre.ethers.getContractFactory('Brand3Slogan');
        const brand3Slogan = await _brand3Slogan.attach(String(brand3SloganAddress.address));
        await brand3Slogan.mint(creatorAddress.address, splitterAddress.address);
        break;
      case 'Get Brand3 Slogan':
        const brand3Slogans = await brand3Factory.getBrand3Slogan();
        console.log(brand3Slogans);
        break;
      // case 'Get Brand Owner':
      //   const brandOwner = await brand3Slogan.getBrandOwner();
      //   console.log(brandOwner);
      //   break;
      case 'Create a New Brand':
        const brandName = await prompt([
          {
            type: 'input',
            name: 'name',
            message: 'Enter the brand name',
          },
        ]);
        const brandSymbol = await prompt([
          {
            type: 'input',
            name: 'symbol',
            message: 'Enter the brand symbol',
          },
        ]);
        const brandWebsite = await prompt([
          {
            type: 'input',
            name: 'website',
            message: 'Enter the brand website',
          },
        ]);
        const brandLogo = await prompt([
          {
            type: 'input',
            name: 'logo',
            message: 'Enter the brand logo',
          },
        ]);
        await brand3Factory.createNewSlogan('0x111', String(brandWebsite), String(brandName), String(brandSymbol), String(brandLogo));
        break;
      case 'Exit':
        process.exit(0);
        break;
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
