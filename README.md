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
    - [Deploy Arbitrum Sepolia Testnet](#deploy-arbitrum-sepolia-testnet)
    - [Interact with Contract](#interact-with-contract)
  - [Deployment](#deployment)
    - [Deploy to Testnet](#deploy-to-testnet)
    - [Verify Contract](#verify-contract)
    - [Deployment Addresses](#deployment-addresses)
  - [Security](#security)
    - [Audit Status](#audit-status)
    - [Access Control (Roles \& Permissions)](#access-control-roles--permissions)
    - [Known Limitations](#known-limitations)
  - [Gas Optimization](#gas-optimization)
  - [Glossary \& FAQ](#glossary--faq)
    - [Core ERC-4337 Terms](#core-erc-4337-terms)
    - [Common Questions](#common-questions)
  - [Contributing](#contributing)
  - [License](#license)

## About

This is an educational implementation of an ERC-4337 (Account Abstraction) smart contract wallet that demonstrates how to build a basic smart contract account using the EntryPoint contract. It showcases signature validation, user operation handling, and fund management for decentralized account abstraction.

### Key Features

- **ERC-4337 Compliant**: Implements the `IAccount` interface for EntryPoint compatibility
- **Owner-Based Validation**: Uses ECDSA signature validation with owner authorization
- **Flexible Execution**: Execute arbitrary transactions through the EntryPoint or directly as owner
- **Fund Management**: Receive ETH and withdraw funds with owner-only permissions
- **Educational Design**: Simple, well-commented code for learning Account Abstraction concepts

**Tech Stack:**
- Solidity ^0.8.24
- Foundry (testing & deployment)
- OpenZeppelin Contracts (Ownable, ECDSA)
- ERC-4337 Account Abstraction Contracts
- Forge Standard Library

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        EOA / User                           │
│                     (Account Owner)                         │
└───────────┬─────────────────────────────────┬───────────────┘
            │                                 │
            │ 1. Sign UserOperation           │ 2. Call execute()
            │                                 │    directly (owner)
            ▼                                 │
┌───────────────────────────────┐             │
│   Bundler / Sequencer         │             │
│  (Bundles multiple UserOps)   │             │
└──────────────┬────────────────┘             │
               │                              │
               │ 2. Call handleOps()          │
               │                              │
               ▼                              │
┌────────────────────────────────────────┐    │
│        EntryPoint Contract             │    │
│    (ERC-4337 Core Hub)                 │    │
│                                        │    │
│  ┌─────────────────────────────┐       │    │
│  │ validateUserOp()            │       │    │
│  │ (Signature Validation)      │       │    │
│  └─────────────────────────────┘       │    │
│                                        │    │
│  ┌─────────────────────────────┐       │    │
│  │ execute()                   │       │    │
│  │ (Execution Phase)           │       │    │
│  └─────────────────────────────┘       │    │
└──────────────┬─────────────────────────┘    │
               │                              │
               │ 3. Validate & Execute        │
               │                              │
               ▼                              ▼ 
┌───────────────────────────────────────────────┐    
│    BasicAccount (Smart Wallet)                │
│                                               │
│  ┌──────────────────────────────┐             │
│  │ validateUserOp()             │             │
│  │ - Recover signer from sig    │             │
│  │ - Verify signer == owner     │             │
│  │ - Pay entry point            │             │
│  └──────────────────────────────┘             │
│                                               │
│  ┌──────────────────────────────┐             │
│  │ execute()                    │             │
│  │ - Call external contracts    │             │
│  │ - Transfer funds             │             │
│  └──────────────────────────────┘             │
│                                               │
│  ┌──────────────────────────────┐             │
│  │ withdraw()                   │             │
│  │ - Owner only withdraw funds  │             │
│  └──────────────────────────────┘             │
└──────────────┬────────────────────────────────┘
               │
               │ 4. Execute Transactions
               │
     ┌─────────┴──────────┐
     │                    │
     ▼                    ▼
┌─────────────────┐  ┌──────────────┐
│  Target Contract│  │  Other Calls │
│  (USDC, etc.)   │  │  (transfers) │
└─────────────────┘  └──────────────┘
```

**Repository Structure:**
```        
foundry-erc4337-account-abstraction/
├── src/
│   └── BasicAccount.sol               # ERC-4337 Smart Wallet Implementation
├── script/
│   ├── DeployBasicAccount.s.sol        # Deployment script
│   ├── HelperConfig.s.sol              # Network configuration
│   └── SendPackedUserOp.s.sol           # UserOperation helper functions
├── test/
│   ├── unit/
│   │   └── BasicAccountTest.t.sol       # Unit tests
│   ├── integration/
│   │   └── DeployBasicAccountTest.t.sol # Integration tests
│   ├── fuzz/
│   │   ├── Handler.t.sol                # Fuzz testing handler
│   │   └── InvariantsTest.t.sol         # Invariant tests
│   └── mocks/
│       └── InvalidReceiver.sol          # Mock for testing failures
├── lib/
│   ├── account-abstraction/            # ERC-4337 core contracts
│   ├── forge-std/                      # Foundry standard library
│   ├── foundry-devops/                 # DevOps utilities
│   └── openzeppelin-contracts/         # OpenZeppelin utilities
├── foundry.toml                        # Foundry configuration
├── Makefile                            # Build automation
└── README.md                           # This file
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

4. **Configure Makefile**
- Change account name in Makefile to the name of your desired encrypted key 
  - change "--account defaultKey" to "--account <YOUR_ENCRYPTED_KEY_NAME>"
  - check encrypted key names stored locally with:

```bash
cast wallet list
```
- **If no encrypted keys found**
  - Encrypt private key to be used securely within foundry:

```bash
cast wallet import <account_name> --interactive
```

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
forge test --mt testFunctionName
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

### Deploy Arbitrum Sepolia Testnet

```bash
make deploy ARGS="--network arb sepolia"
```

### Interact with Contract

You can interact with the BasicAccount contract using Foundry's `cast` command or through the provided scripts.

**1. Fund the BasicAccount with ETH:**
```bash
cast send <BASIC_ACCOUNT_ADDRESS> --value 1ether --rpc-url $SEPOLIA_RPC_URL --account defaultKey
```

**2. Check BasicAccount balance:**
```bash
cast balance <BASIC_ACCOUNT_ADDRESS> --rpc-url $SEPOLIA_RPC_URL
```

**3. Withdraw funds (owner only):**
```bash
cast send <BASIC_ACCOUNT_ADDRESS> "withdraw(uint256)" 500000000000000000 --rpc-url $SEPOLIA_RPC_URL --account defaultKey
```

**4. Send a packed user operation through EntryPoint:**
```bash
# First, set your secondary address for approvals
export SECONDARY_ADDRESS=0x... # address to approve USDC to

# Run the script that creates and sends a user operation
forge script script/SendPackedUserOp.s.sol:SendPackedUserOp --rpc-url $ARB_SEPOLIA_RPC_URL --account defaultKey --broadcast -vvvv

# Or more simply with make commands
make sendPackedUserOp ARGS="--network arb sepolia"
```

**5. Execute a transaction as owner:**
```bash
# Call USDC mint through the BasicAccount
cast send <BASIC_ACCOUNT_ADDRESS> "execute(address,uint256,bytes)" <USDC_ADDRESS> 0 0x<ENCODED_MINT_DATA> \
  --rpc-url $SEPOLIA_RPC_URL --account defaultKey
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
| ARB Sepolia | `0xBD2cd0cEF56260d291fc55f4D112d55DAA495226` | [View on Etherscan](https://sepolia.etherscan.io) |
| ARB Mainnet | `TBD` | [View on Etherscan](https://etherscan.io) |

## Security

### Audit Status

⚠️ **This contract has not been audited.** Use at your own risk.

For production use, consider:
- Professional security audit
- Bug bounty program
- Gradual rollout with monitoring

### Access Control (Roles & Permissions)

The BasicAccount implements two-level access control using OpenZeppelin's `Ownable` and ERC-4337's EntryPoint contract:

**Owner Permissions (OpenZeppelin `Ownable`):**
- **`withdraw(uint256 amount)`**: Only the account owner can withdraw ETH from the contract
- **`transferOwnership(address newOwner)`**: Owner can transfer ownership to another address
- **`execute(address, uint256, bytes)` (called directly)**: Owner can directly execute transactions without going through EntryPoint

**EntryPoint Permissions:**
- **`validateUserOp(PackedUserOperation, bytes32, uint256)`**: EntryPoint validates user operations by checking the signature against the owner's address
- **`execute(address, uint256, bytes)` (called via EntryPoint)**: EntryPoint can execute operations on behalf of the owner after validation

**Signature Validation Scheme:**
- Uses **ECDSA** signature recovery with **EIP-191** message hash formatting
- Signer must match the account owner (no multi-sig support in basic implementation)
- Returns `SIG_VALIDATION_SUCCESS` (0) if signature is valid, `SIG_VALIDATION_FAILED` (1) otherwise

**Access Control Matrix:**

| Function | Owner | EntryPoint | Other |
|----------|-------|-----------|-------|
| `receive()` | ✓ | ✓ | ✓ |
| `validateUserOp()` | ✗ | ✓ | ✗ |
| `execute()` | ✓ | ✓ | ✗ |
| `withdraw()` | ✓ | ✗ | ✗ |
| `getEntryPoint()` | ✓ | ✓ | ✓ |

**Access Control Vulnerabilities & Mitigations:**

⚠️ **Risk**: Single owner model has centralization risk
- **Mitigation**: In production, consider implementing a multi-sig wallet as owner or using social recovery

⚠️ **Risk**: No nonce validation (commented out in `validateUserOp()`)
- **Mitigation**: For production, implement nonce checking to prevent replay attacks

⚠️ **Risk**: Signature validation does not check operation deadlines
- **Mitigation**: Add timestamp validation if timing is critical for your use case

### Known Limitations

- **Single Signer Model**: Only one owner can validate operations - no multi-sig support. Consider using a multi-sig wallet as the owner in production.

- **No Nonce Validation**: The `validateUserOp()` function doesn't validate nonces but the entry point contract ensures uniqueness. Not strictly needed but could add logic to ensure ordered execution or some other logic.

- **Basic Signature Scheme**: Uses simple ECDSA with EOA signatures. No support for account abstraction-specific features like batching or scheduled operations.

- **No Transaction Batching**: Each user operation can only execute one transaction. For complex interactions, multiple transactions are required.

- **No Paymaster Support**: No integration with paymasters. All transaction fees must be paid by the account itself.

- **Hardcoded Gas Limits**: Gas limits in `SendPackedUserOp.s.sol` are hardcoded and may not be sufficient for complex transactions.

**Centralization Risks:**
- Full control by a single EOA owner - one compromised key means loss of all funds
- Owner can withdraw all funds at any time without restrictions
- No governance or community oversight in basic implementation

**EntryPoint Dependencies:**
- Relies completely on EntryPoint contract for transaction bundling and validation
- EntryPoint contract must be trusted and properly implemented
- Any bugs in EntryPoint could compromise account security

## Gas Optimization

| Function | Operation | Typical Gas Cost |
|----------|-----------|------------------|
| `validateUserOp()` | Signature validation | ~35-41k |
| `execute()` | Call execution (varies by target) | ~25k+ |
| `withdraw()` | Fund withdrawal | ~24-32k |
| `receive()` | Receive ETH | ~21k |

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

## Glossary & FAQ

### Core ERC-4337 Terms

**UserOperation**
- A user-signed transaction-like object sent by a user to a bundler
- Contains data needed for account validation and execution
- Bundlers collect multiple UserOperations and submit them to the EntryPoint
- Cannot directly interact with blockchain - requires EntryPoint processing

**EntryPoint**
- The singleton contract that handles UserOperation bundling and validation
- Acts as the main hub for all account abstraction operations
- Calls `validateUserOp()` on the account to verify the signature
- Calls `execute()` to perform the actual transaction
- Manages gas refunds and compensation for bundlers

**Account / Smart Wallet**
- A smart contract that acts like a user account
- Implements the `IAccount` interface with `validateUserOp()` and `execute()` functions
- Controls user funds and executes transactions
- Can have custom validation logic (signatures, multi-sig, biometric, etc.)
- **In this project**: `BasicAccount` contract

**Bundler**
- An external service that collects UserOperations from users
- Bundles multiple operations together for efficiency
- Submits the bundle to the EntryPoint
- Gets compensated for gas costs in the `verificationGas` and `callGasLimit` fields
- Not part of the smart contracts - it's an off-chain service

**Paymaster**
- A contract that can sponsor gas fees for UserOperations
- Allows accounts to use any token (not just ETH) to pay for gas
- Interfaces with EntryPoint for validation and payment
- **Not implemented** in BasicAccount (all fees must be paid by the account in ETH)

**initCode**
- Code used to deploy the account contract on first use
- Contains the factory contract address and initialization data
- Executed only once (when `nonce == 0`)
- Empty for already-deployed accounts like in this project

**callData**
- The encoded function call to execute on the account
- Typically encodes a call to the `execute()` function
- Specifies the target address, value, and function data

**ValidationData**
- Return value from `validateUserOp()`
- `0` = signature valid and operation can proceed (`SIG_VALIDATION_SUCCESS`)
- `1` = signature invalid, operation will fail (`SIG_VALIDATION_FAILED`)

### Common Questions

**Q: How does BasicAccount validate transactions?**
A: It recovers the signer from the ECDSA signature and verifies the signer matches the account owner. Only the owner can authorize transactions.

**Q: What happens if my account runs out of ETH?**
A: The EntryPoint will revert the operation. Your account must maintain enough ETH to cover gas costs. Consider using a Paymaster for sponsored transactions.

**Q: Can I use this on Mainnet?**
A: **Not recommended.** This is an educational implementation and has not been audited. Only use on testnets or in development environments.

**Q: How do I add multi-sig support?**
A: Replace the signature validation logic in `_validateSignature()` to verify multiple signatures instead of just one. You'd also need to track which signers have approved the operation.

**Q: What's the difference between `execute()` called by EntryPoint vs. owner?**
A: Both paths execute the same function, but EntryPoint ensures proper validation happened first and handles gas accounting. Owner direct calls bypass validation (for convenience) but still require the owner key.

**Q: Why is nonce validation commented out?**
A: It's a simplified example. In production, you MUST implement nonce validation to prevent replay attacks. The same UserOperation could be replayed multiple times without proper nonce handling.

**Q: Can I batch multiple transactions in one UserOperation?**
A: Not in BasicAccount's current implementation. Each UserOperation executes one `execute()` call. To batch, you'd need to use delegatecall or create a separate batching contract.

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