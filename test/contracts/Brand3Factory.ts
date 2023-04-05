import { Signer } from 'ethers';
import { ethers } from 'hardhat';
import { fastForward, restoreSnapshot, takeSnapshot } from '../utils';
import { deployTestSystem, TestSystemContractsType } from '../utils/deployTestSystem';
import { expect } from 'chai';

describe('Brand3Factory uint tests', async () => {
  let deployer: Signer;
  let user: Signer;
  let contracts: TestSystemContractsType;
  let snapshotId: number;

  before(async function () {
    [deployer, user] = await ethers.getSigners();
    contracts = await deployTestSystem(deployer);
    snapshotId = await takeSnapshot();
  });

  beforeEach(async function () {
    await restoreSnapshot(snapshotId);
    snapshotId = await takeSnapshot();
  });

  describe('Create new Slogan Successfully', async () => {
    it('should create new slogan successfully', async () => {
      await contracts.brand3Factory.createNewSlogan(
        '0x111',
        'https://brand3Slogan.com',
        'IT MAKES SMART CONTRACT SAFU',
        'IMSCS',
        'https://brand3Logo.com',
      );
      const brand3Slogans = await contracts.brand3Factory.getBrand3Slogan();
      expect(brand3Slogans.length).to.equal(1);
    });
  });
});
