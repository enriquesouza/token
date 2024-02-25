# EnriCash :: ERC20 Token with ICO and Compound APY Staking

* ALERT: I removed all sensitive data from this repo.

## Project Overview

This project introduces an ERC20 token, equipped with an Initial Coin Offering (ICO) and a staking mechanism that rewards holders with compound annual percentage yield (APY). Utilizing the solidity version 0.8.14, this project integrates advanced mathematical operations for interest calculations and staking rewards, leveraging the DSMath library from DappHub for precise arithmetic operations.

The tokenomics incorporate a smart contract for ICO, facilitating token sales with locked periods, and a staking contract that calculates rewards based on continuously compounded interest, providing token holders an opportunity to earn passive income. Furthermore, the project adheres to best practices in contract development, including security measures like reentrancy guards, and is structured for easy deployment and interaction on the Ethereum blockchain.

### Features

- **ERC20 Token**: Standard token implementation with additional functionality for staking.
- **Initial Coin Offering (ICO)**: Allows investors to purchase tokens at a predefined rate, with functionalities to set and manage sales.
- **Compound APY Staking**: Reward system for token holders that stake their tokens, accruing interest over time based on a continuously compounded rate.
- **DSMath Integration**: Utilizes the DSMath library for high-precision arithmetic operations, ensuring accurate interest calculations.
- **Security**: Includes reentrancy guards and ownership checks to prevent common vulnerabilities.

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/en/) and npm installed.
- [Truffle](https://www.trufflesuite.com/truffle) for smart contract compilation and deployment.
- [Ganache](https://www.trufflesuite.com/ganache) for a local Ethereum blockchain, or access to testnet/mainnet nodes.

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Install dependencies:
   ```
   npm install
   ```

### Smart Contract Deployment

1. Compile contracts:
   ```
   truffle compile
   ```
2. Migrate contracts to your chosen network (development, testnet, or mainnet) by modifying the `truffle-config.js` file to include your network settings and then run:
   ```
   truffle migrate --network <network-name>
   ```

## Usage

### Interacting with the Smart Contracts

- **Token Purchase (ICO)**: Participate in the ICO by sending ETH to the ICO contract in exchange for tokens.
- **Staking**: Stake your tokens via the staking contract to earn interest. Interest is calculated based on the duration of the stake and the current APY rate.
- **Interest Calculation**: Utilize the `Interest` contract methods to calculate earned interest on staked tokens.

### Contract Methods

- `stake(uint256 amount)`: Stake a specified amount of tokens.
- `unstake()`: Withdraw your staked tokens along with any accrued interest.
- `mint(address _account, uint256 _amount)`: Mint new tokens to a specified account (restricted to contract owner).
- `burn(address _account, uint256 _amount)`: Burn tokens from a specified account (restricted to contract owner).

## Technical Details

### DSMath Library

Leverages the DSMath library for decimal and fixed-point arithmetic in Solidity, enabling precise calculations for interest rates and staking rewards.

### Interest Calculation

Implements an approximation of continuously compounded interest, facilitating a dynamic and competitive APY model for stakers.

## Security Considerations

The project includes multiple security mechanisms, such as reentrancy guards to prevent re-entrancy attacks and ownership checks to ensure that sensitive actions can only be performed by the contract owner. Additionally, the contracts have undergone audits to identify and mitigate potential vulnerabilities.


### Verifying Contracts

After deploying your contracts, verify them on Etherscan (or a similar explorer for the network you're using) to make the source code available and verifiable by others. Use the Truffle plugin to simplify this process:

```bash
npx truffle run verify YourContractName@YourContractAddress --network <network-name>
```

### Environmental Variables

For deploying and interacting with your contracts, manage environmental variables to switch between different networks (development, testnets, mainnet) seamlessly. Use `.env` files to configure network-specific parameters and API keys. Example:

```plaintext
INFURA_API_KEY=your_infura_api_key
PRIVATE_KEY=your_private_key
```

### DSMath Library

Incorporates DSMath for high-precision arithmetic operations in Solidity, essential for accurate interest calculation in the staking mechanism.

### Additional Scripts

- **Increasing Memory for Node.js**:
  To handle large compilations, increase Node.js memory:

  ```bash
  export NODE_OPTIONS="--max-old-space-size=16384" # Increase to 16 GB
  ```

- **Generating UML**:
  To visualize contract inheritance and interaction, generate UML diagrams using:

  ```bash
  npx sol2uml
  ```

## Environment Configuration

This project utilizes environment variables to manage sensitive information securely. These variables are stored in `.env` files, which should never be committed to version control. Below is a guide to setting up your `.env` files for different environments.

### Required `.env` Files

1. **.env.local** - For local development and testing.
2. **.env.prod** - For production deployments.
3. **.env.test** - For test networks like Ropsten, Rinkeby, or Mumbai.

### Common Environment Variables

- `INFURA_API_KEY` - Your Infura project API key for accessing Ethereum network nodes.
- `MNEMONIC` - The mnemonic phrase of your wallet used for deploying contracts.
- `PRIVATE_KEY` - Your private key for the deploying wallet (alternative to MNEMONIC).
- `ETHERSCAN_API_KEY` - Your Etherscan API key for verifying contracts.

### `.env` File Template

Create a `.env.local`, `.env.prod`, and `.env.test` file in the root directory of your project with the following template:

```plaintext
# Infura
INFURA_API_KEY=your_infura_project_id

# Wallet
MNEMONIC=your_wallet_mnemonic
PRIVATE_KEY=your_wallet_private_key

# Etherscan
ETHERSCAN_API_KEY=your_etherscan_api_key

# Contract Deployment
TOKEN_MAX_CAP=your_token_max_cap
TOKEN_NAME=YourTokenName
TOKEN_SYMBOL=YTS
ICO_PRICE=your_ico_price
TOKEN_TERM=your_token_term
TOKEN_STAKING_RATE=your_staking_rate

# Other Variables as needed
```

### Securing `.env` Files

- Do not commit `.env` files to version control. Add them to your `.gitignore` file.
- Use different `.env` files for different environments (development, testing, production) to separate concerns and enhance security.
- Regularly rotate API keys and mnemonics, and update the `.env` files accordingly.

## Getting Started

Follow the project setup instructions above, and ensure you have the correct `.env` file configured for your working environment before compiling, deploying, or testing the contracts.
