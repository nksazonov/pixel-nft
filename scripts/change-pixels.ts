/* eslint-disable @typescript-eslint/no-non-null-assertion */
import { ethers } from 'hardhat';

import type { NFT } from '../typechain/contracts/NFT';

interface ChangePixelPayload {
  row: number;
  col: number;
  color: number;
}

async function main(): Promise<void> {
  const nftAddress = process.env.NFT_ADDRESS!;
  const NFT = (await ethers.getContractAt('NFT', nftAddress)) as NFT;

  const tokenID = process.env.TOKEN_ID ?? 0;
  const row = process.env.ROW as unknown as number;
  const color = process.env.COLOR as unknown as number;
  const pixelAmount = (await NFT.tokenPixelSize()) as number;

  const payloads = [] as ChangePixelPayload[];

  for (let i = 0; i < pixelAmount; i++) {
    payloads.push({ row, col: i, color });
  }

  await NFT.changePixels(tokenID, payloads);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
/* eslint-enable @typescript-eslint/no-non-null-assertion */
