require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');
const NonceTrackerSubprovider = require("web3-provider-engine/subproviders/nonce-tracker")

const fs = require('fs');
const mnemonic = fs.readFileSync('.secret').toString().trim();
const privateKey = 'YOUR_ID';
const endpointUrl = 'https://kovan.infura.io/v3/YOUR_ID';

module.exports = {
    plugins: ['truffle-plugin-verify'],

    api_keys: {
        etherscan: 'YOUR_ID',
        optimistic_etherscan: 'MY_API_KEY',
        arbiscan: 'MY_API_KEY',
        bscscan: 'MY_API_KEY',
        snowtrace: 'MY_API_KEY',
        polygonscan: 'YOUR_ID',
        ftmscan: 'MY_API_KEY',
        hecoinfo: 'MY_API_KEY',
        moonscan: 'MY_API_KEY',
        kovan: 'YOUR_ID',
    },

    networks: {
        development: {
            host: '127.0.0.1', // Localhost (default: none)
            port: 8545, // Standard Ethereum port (default: none)
            network_id: '*', // Any network (default: none)
            allowUnlimitedContractSize: true,
            timeoutBlocks: 200,
            skipDryRun: true,
            websockets: true,
            networkCheckTimeout: 1000000,
            //confirmations: 1,
            //gas: 8500000, // Gas sent with each transaction (default: ~6700000)
            //gasPrice: 20000000000, // 20 gwei (in wei) (default: 100 gwei)
            //provider: () => new HDWalletProvider(mnemonic, `ws://localhost:8545`),
            provider: () =>
                new HDWalletProvider({
                    mnemonic: mnemonic,
                    providerOrUrl: `ws://localhost:8545`,
                    numberOfAddresses: 100,
                }),
        },
        neon_devnet: {
            provider: () => new HDWalletProvider(mnemonic, `https://proxy.devnet.neonlabs.org/solana`),
            network_id: 245022926,
            confirmations: 2,
            timeoutBlocks: 200,
            skipDryRun: true,
        },
        neon_testnet: {
            provider: () => new HDWalletProvider(mnemonic, `https://proxy.testnet.neonlabs.org/solana`),
            network_id: 245022940,
            confirmations: 10,
            timeoutBlocks: 200,
            skipDryRun: true,
        },
        bsc_testnet: {
            provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
            network_id: 97,
            confirmations: 10,
            timeoutBlocks: 200,
            skipDryRun: true,
        },
        bsc: {
            provider: () => new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
            network_id: 56,
            confirmations: 10,
            timeoutBlocks: 200,
            skipDryRun: true,
        },
        mumbai: {
            provider: () =>
                new HDWalletProvider(mnemonic, `wss://polygon-mumbai.infura.io/ws/v3/YOUR_ID`),
            network_id: 80001,
            gas: 4000000, //make sure this gas allocation isn't over 4M, which is the max
            allowUnlimitedContractSize: true,
            timeoutBlocks: 200,
            skipDryRun: true,
            websockets: true,
            networkCheckTimeout: 1000000,
        },
        matic: {
            provider: () => {
                let wallet = new HDWalletProvider(
                    mnemonic,
                    `wss://polygon-mainnet.infura.io/ws/v3/YOUR_ID`
                );
                let nonceTracker = new NonceTrackerSubprovider();
                wallet.engine._providers.unshift(nonceTracker);
                nonceTracker.setEngine(wallet.engine);
                return wallet;
            },
            // new HDWalletProvider(mnemonic, `https://polygon-mainnet.infura.io/v3/YOUR_ID`),
            network_id: 137,
            skipDryRun: true,
            websockets: true,
            timeoutBlocks: 50000,
            networkCheckTimeout: 10000000,
            confirmations: 1,
            gas: process.env.GAS_LIMIT, //make sure this gas allocation isn't over 4M, which is the max
            allowUnlimitedContractSize: true,
            gasPrice: process.env.GAS_PRICE, // 20 gwei (in wei) (default: 100 gwei)
            // maxFeePerGas: 3000000000,
            // maxPriorityFeePerGas: 2500000000,
        },
        ropsten: {
            provider: function () {
                return new HDWalletProvider(mnemonic, 'wss://ropsten.infura.io/ws/v3/YOUR_ID');
            },
            network_id: 3,
            gas: 4000000, //make sure this gas allocation isn't over 4M, which is the max
            allowUnlimitedContractSize: true,
            timeoutBlocks: 200,
            skipDryRun: true,
            websockets: true,
            networkCheckTimeout: 1000000,
        },
        rinkeby: {
            provider: function () {
                return new HDWalletProvider(mnemonic, 'wss://rinkeby.infura.io/ws/v3/YOUR_ID');
            },
            network_id: 4,
            gas: 4000000, //make sure this gas allocation isn't over 4M, which is the max
            allowUnlimitedContractSize: true,
            timeoutBlocks: 200,
            skipDryRun: true,
            websockets: true,
            networkCheckTimeout: 1000000,
        },
    },

    // Set default mocha options here, use special reporters etc.
    mocha: {
        enableTimeouts: false,
        before_timeout: 60000 * 60 * 24,
    },

    // Configure your compilers
    compilers: {
        solc: {
            version: '0.8.14', // Fetch exact version from solc-bin (default: truffle's version)
            // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
            settings: {
                // See the solidity docs for advice about optimization and evmVersion
                optimizer: {
                    enabled: true,
                    runs: 200000,
                },
                evmVersion: 'byzantium',
            },
        },
    },
};
