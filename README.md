# Foundry ERC4337 Account Abstraction

**⚠️ This is an educational project - not audited, use at your own risk**

## Table of Contents

- [Foundry ERC4337 Account Abstraction](#foundry-erc4337-account-abstraction)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
    - [Key Features](#key-features)
    - [Architecture](#architecture)
  - [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [Quickstart](#quickstart)
    - [Environment Setup](#environment-setup)
  - [Usage](#usage)
    - [Build](#build)
    - [Testing](#testing)
    - [Test Coverage](#test-coverage)
    - [Deploy Locally](#deploy-locally)
    - [Interact with Contract](#interact-with-contract)
  - [Deployment](#deployment)
    - [Deploy to Testnet](#deploy-to-testnet)
    - [Verify Contract](#verify-contract)
    - [Deployment Addresses](#deployment-addresses)
  - [Security](#security)
    - [Audit Status](#audit-status)
    - [Known Limitations](#known-limitations)
  - [Gas Optimization](#gas-optimization)
  - [Contributing](#contributing)
  - [License](#license)

## About

[1-2 sentence description of what the contract does and its purpose]

### Key Features

- Feature 1
- Feature 2
- Feature 3

**Tech Stack:**
- Solidity ^0.8.x
- Foundry
- [Other dependencies]

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Users/EOAs                          │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               │ fund()                       │ withdraw()
               │                              │ (owner only)
               ▼                              ▼
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│                      Main Contract                           │
│                                                              │
│  ┌────────────────┐        ┌──────────────────┐              │
│  │   Funders      │        │   Funding Goals  │              │
│  │   Tracking     │        │   & Amounts      │              │
│  └────────────────┘        └──────────────────┘              │
│                                                              │
└───────────────────┬──────────────────────────────────────────┘
                    │
                    │ getConversionRate()
                    │
                    ▼
          ┌─────────────────────┐
          │  Chainlink Oracle   │
          │   Price Feed        │
          └─────────────────────┘
```

**Repository Structure:**
```
project-name/
├── src/
│   ├── MainContract.sol       # Core contract logic
│   └── PriceConverter.sol     # Helper library (if applicable)
├── script/
│   ├── DeployContract.s.sol   # Deployment script
│   └── Interactions.s.sol     # Interaction scripts
├── test/
│   ├── unit/
│   │   └── ContractTest.t.sol
│   └── integration/
│       └── InteractionsTest.t.sol
└── lib/                        # Dependencies
```

## Getting Started

### Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Verify installation: `git --version`
- [foundry](https://getfoundry.sh/)
  - Verify installation: `forge --version`

### Quickstart

```bash
git clone https://github.com/0xGearhart/foundry-account-abstraction-basic
cd foundry-account-abstraction-basic
make install
forge build
```

### Environment Setup

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Configure your `.env` file:**
   ```bash
   ETH_MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key
   ETH_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
   ARB_MAINNET_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/your-api-key
   ARB_SEPOLIA_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/your-api-key
   ETHERSCAN_API_KEY=your_etherscan_api_key_here
   DEFAULT_KEY_ADDRESS=public_address_of_your_encrypted_private_key_here
   ```

3. **Get testnet ETH:**
   - Sepolia Faucet: [cloud.google.com/application/web3/faucet/ethereum/sepolia](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

**⚠️ Security Warning:**
- Never commit your `.env` file
- Never use your mainnet private key for testing
- Use a separate wallet with only testnet funds

## Usage

### Build

Compile the contracts:

```bash
forge build
```

### Testing

Run the test suite:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vvv
```

Run specific test:

```bash
forge test --match-test testFunctionName
```

### Test Coverage

Generate coverage report:

```bash
forge coverage
```

### Deploy Locally

Start a local Anvil node:

```bash
make anvil
```

Deploy to local node (in another terminal):

```bash
make deploy
```

### Interact with Contract

[Examples of how to interact with your contract using cast or scripts]

```bash
# Example command
cast send <CONTRACT_ADDRESS> "functionName()" --rpc-url $SEPOLIA_RPC_URL --account defaultKey
```

## Deployment

### Deploy to Testnet

Deploy to Sepolia:

```bash
make deploy ARGS="--network sepolia"
```

Or using forge directly:

```bash
forge script script/DeployContract.s.sol:DeployContract --rpc-url $SEPOLIA_RPC_URL --account defaultKey --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
```

### Verify Contract

If automatic verification fails:

```bash
forge verify-contract <CONTRACT_ADDRESS> src/MainContract.sol:MainContract --chain-id 11155111 --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deployment Addresses

| Network | Contract Address | Explorer |
|---------|------------------|----------|
| Sepolia | `TBD` | [View on Etherscan](https://sepolia.etherscan.io) |
| Mainnet | `TBD` | [View on Etherscan](https://etherscan.io) |

## Security

### Audit Status

⚠️ **This contract has not been audited.** Use at your own risk.

For production use, consider:
- Professional security audit
- Bug bounty program
- Gradual rollout with monitoring

### Known Limitations

- [Limitation 1 - e.g., centralized owner control]
- [Limitation 2 - e.g., no withdrawal limits]
- [Limitation 3 - e.g., relies on external oracle]

**Centralization Risks:**
- [Explain any admin/owner privileges]

**Oracle Dependencies:**
- [Explain reliance on Chainlink or other oracles]

## Gas Optimization

| Function | Gas Cost |
|----------|----------|
| `function1` | ~XXX,XXX |
| `function2` | ~XXX,XXX |
| `function3` | ~XXX,XXX |

Generate gas report:

```bash
forge test --gas-report
```

Generate gas snapshot:

```bash
forge snapshot
```

Compare gas changes:

```bash
forge snapshot --diff
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Disclaimer:** This software is provided "as is", without warranty of any kind. Use at your own risk.

**Built with [Foundry](https://getfoundry.sh/)**