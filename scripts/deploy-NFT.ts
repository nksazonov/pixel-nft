import { ethers } from 'hardhat';

import type { NFT } from '../typechain/contracts/NFT';

async function main(): Promise<void> {
  const NFTFactory = await ethers.getContractFactory('NFT');
  const NFT = (await NFTFactory.deploy()) as NFT;
  await NFT.deployed();

  console.log('Contract deployed to:', NFT.address);

  await NFT.mint();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
