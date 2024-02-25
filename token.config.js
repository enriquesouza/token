require('dotenv').config();
const Web3 = require('web3');
const { Util } = require('./lib/utils3');
const { time } = require('@openzeppelin/test-helpers');
const { fromEtherToBigNumberWei } = new Util(new Web3());
const intMaxCap = process.env.TOKEN_MAX_CAP;
const maxCap = fromEtherToBigNumberWei(`${intMaxCap}`);
const maxManualMintable = fromEtherToBigNumberWei(`400000000`);
const stakingDuration = time.duration.years(10);

exports.TOKEN_DETAIL = {
    name: process.env.TOKEN_NAME,
    symbol: process.env.TOKEN_SYMBOL,
    maxCap,
    stakingRate: fromEtherToBigNumberWei(process.env.TOKEN_STAKING_RATE.toString()),
    stakingDuration,
    maxManualMintable,
    calculatedStakingYearlyRateInRay: '1000000004756468797564687976',
};

exports.TOKEN_ICO = {
    name: process.env.ICO_NAME,
    symbol: process.env.ICO_SYMBOL,
    price: String(process.env.ICO_PRICE),
    term: String(process.env.TOKEN_TERM),
};

exports.TOKEN_ICO_ATM = {
    name: process.env.ICO_ATM_NAME,
    symbol: process.env.ICO_ATM_SYMBOL,
    price: String(process.env.ICO_ATM_PRICE),
    term: String(process.env.TOKEN_TERM),
};

exports.TOKEN_SWAP = {
    name: process.env.SWAP_NAME,
    symbol: process.env.SWAP_SYMBOL,
};

exports.TOKEN_DAI = {
    name: process.env.DAI_NAME,
    symbol: process.env.DAI_SYMBOL,
};

exports.GOVERNANCE = {
    founders: [
        {
            label: 'Founder',
            installments: process.env.FOUNDERS_INSTALLMENTS,
            percentage: 0.1,
            address: process.env.PERSON_0,
        },
        {
            label: 'Founder',
            installments: process.env.FOUNDERS_INSTALLMENTS,
            percentage: 0.1,
            address: process.env.PERSON_1,
        },
        {
            label: 'Founder',
            installments: process.env.FOUNDERS_INSTALLMENTS,
            percentage: 0.1,
            address: process.env.PERSON_2,
        },
        {
            label: 'Founder',
            installments: process.env.FOUNDERS_INSTALLMENTS,
            percentage: 0.1,
            address: process.env.PERSON_3,
        },
        {
            label: 'Founder',
            installments: process.env.FOUNDERS_INSTALLMENTS,
            percentage: 0.1,
            address: process.env.PERSON_4,
        },
    ],
    developers: [
        
    ],
    companyAreas: [
        {
            label: 'Development Area',
            installments: process.env.AREAS_INSTALLMENTS,
            percentage: 0.04,
            address: process.env.DEV,
        },
        {
            label: 'Marketing Area',
            installments: process.env.AREAS_INSTALLMENTS,
            percentage: 0.05,
            address: process.env.MKT,
        },
        {
            label: 'Charity',
            installments: process.env.AREAS_INSTALLMENTS,
            percentage: 0.001,
            address: process.env.CHARITY,
        },
    ],
    pool: {
        label: 'Liquidity Pool',
        installments: 1,
        percentage: 0.1,
        address: process.env.POOL,
    },
    preSale: {
        label: 'PreSale',
        address: process.env.PRE_SALE,
    },
    airDrop: {
        label: 'Airdrop & Listing agreements',
        address: process.env.AIR_DROP,
        installments: 1,
        percentage: 0.009,
    },
};
