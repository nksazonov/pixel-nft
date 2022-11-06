import 'dotenv/config';

import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import type { HardhatUserConfig } from 'hardhat/types';

const ACCOUNTS = process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [];

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.16',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
  networks: {
    ethereum: {
      url: process.env.ETHEREUM_URL ?? '',
      accounts: ACCOUNTS,
    },
    goerli: {
      url: process.env.GOERLI_URL ?? '',
      accounts: ACCOUNTS,
    },
    polygon: {
      url: process.env.POLYGON_URL ?? '',
      accounts: ACCOUNTS,
    },
    mumbai: {
      url: process.env.MUMBAI_URL ?? '',
      accounts: ACCOUNTS,
    },
    generic: {
      url: process.env.GENERIC_URL ?? '',
      chainId: Number.parseInt(process.env.GENERIC_CHAIN_ID ?? '0'),
      gasPrice: process.env.GENERIC_GAS_PRICE
        ? Number.parseInt(process.env.GENERIC_GAS_PRICE)
        : 'auto',
      accounts: ACCOUNTS,
    },
  },
};

export default config;
