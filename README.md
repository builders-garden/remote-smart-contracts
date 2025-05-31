# Remote Protocol

![Remote Protocol Banner](https://via.placeholder.com/800x400/1a1a1a/ffffff?text=Remote+Protocol)

Remote is a chain abstraction protocol that simplifies access to DeFi across any blockchain. It uses cross-chain messaging and remote smart accounts tied to the same wallet address across networks, allowing users to interact with top DeFi protocols through a single transaction, no matter which chain they are on.

## Overview

Remote aims to bring DeFi to ecosystems with limited native activity by offering a unified way to discover and use DeFi across all chains. For example, a user on ChainX can deposit into Aave's USDC market on Base in one transaction, without leaving ChainX. Managing or closing the position later is just as simple a transaction from ChainX.

The protocol is built on smart accounts based on Safe, which are controlled using cross-chain messages sent through LayerZero. This enables seamless DeFi interactions from any chain with just one wallet.

### The Core Innovation

Using **Portals API**, Remote is able to perform a huge variety of DeFi operations on **Core chains** (Base, Arbitrum, etc.) while users never need to leave **periphery chains** like Flow, Rootstock, or Flare. There's no need for traditional bridges or complex multi-step processes - users just remotely control their accounts on core chains using their preferred chain, and can withdraw from these core chain DeFi protocols directly back to their preferred chain.

**Remote unlocks easy DeFi access for chains that are struggling with users bridging away their assets permanently due to lack of opportunities compared to the Core chains we support.** Instead of losing users and liquidity to other ecosystems, periphery chains can now offer their users access to the best DeFi protocols across all chains while keeping them engaged in their native ecosystem.

## Architecture

### Core Components

The `/src` directory contains the following smart contracts:

- **`Remote.sol`**: Main smart account contract based on Safe that handles cross-chain DeFi operations via LayerZero and Stargate
- **`Factory.sol`**: CREATE2 factory for deterministic deployment of Remote smart accounts across chains
- **`Constants.sol`**: Network constants and contract addresses for supported chains

### How It Works

1. **Smart Account Deployment**: Users deploy a Remote smart account using the Factory contract, creating the same address across all supported chains
2. **Cross-Chain Messaging**: Actions are initiated from any chain and executed on the target chain via LayerZero messaging
3. **DeFi Integration**: The Remote contract automatically handles token transfers, approvals, and protocol interactions
4. **Unified Experience**: Users can access DeFi on any chain through a single interface and transaction

### Supported Operations

- ✅ Cross-chain token transfers via Stargate
- ✅ Automated DeFi protocol interactions (deposits, withdrawals)
- ✅ Batch operations across multiple chains
- ✅ Native and ERC20 token support
- ✅ Composable transactions with custom logic

### Supported Networks

- **Base** (Chain ID: 8453, EID: 30184)
- **Arbitrum** (Chain ID: 42161, EID: 30110)
- **Flow** (Chain ID: 747, EID: 30336)
- **Flare** (Chain ID: 14, EID: 30295)
- **Rootstock** (Chain ID: 30, EID: 30333)

## Getting Started

### Prerequisites

- 🔸 [Node.js](https://nodejs.org/en/download) (v16+ recommended)
- 🔸 [Foundry](https://book.getfoundry.sh/getting-started/installation)
- 🔸 Funded wallet with native tokens on your preferred chain

### Installation

```shell
# Install dependencies
yarn install

# Build contracts
forge build

# Run tests
forge test
```

### Environment Setup

Create a `.env` file in the root directory:

```env
PRIVATE_KEY=your_private_key_here

# RPC URLs
BASE_RPC_URL=https://mainnet.base.org
ARB_RPC_URL=https://arb1.arbitrum.io/rpc
FLOW_RPC_URL=https://mainnet.evm.nodes.onflow.org
FLARE_RPC_URL=https://flare-api.flare.network/ext/C/rpc
ROOTSTOCK_RPC_URL=https://public-node.rsk.co

# LayerZero Endpoints
BASE_ENDPOINT_ADDRESS=0x1a44076050125825900e736c501f859c50fE728c
ARB_ENDPOINT_ADDRESS=0x1a44076050125825900e736c501f859c50fE728c
FLOW_ENDPOINT_ADDRESS=0xcb566e3B6934Fa77258d68ea18E931fa75e1aaAa
FLARE_ENDPOINT_ADDRESS=0x1a44076050125825900e736c501f859c50fE728c
ROOTSTOCK_ENDPOINT_ADDRESS=0xcb566e3B6934Fa77258d68ea18E931fa75e1aaAa

# Stargate Pool Addresses
BASE_STARGATE_ADDRESS=0xdc181Bd607330aeeBEF6ea62e03e5e1Fb4B6F7C7
ARB_STARGATE_ADDRESS=0xA45B5130f36CDcA45667738e2a258AB09f4A5f7F
FLOW_STARGATE_ADDRESS=0x45f1A95A4D3f3836523F5c83673c797f4d4d263B
FLARE_STARGATE_ADDRESS=0x8e8539e4CcD69123c623a106773F2b0cbbc58746
ROOTSTOCK_STARGATE_ADDRESS=0x45f1A95A4D3f3836523F5c83673c797f4d4d263B

# Portal Router (DeFi protocol integration)
BASE_PORTAL_ROUTER_ADDRESS=your_portal_router_address
ARB_PORTAL_ROUTER_ADDRESS=your_portal_router_address
FLOW_PORTAL_ROUTER_ADDRESS=your_portal_router_address
FLARE_PORTAL_ROUTER_ADDRESS=your_portal_router_address
ROOTSTOCK_PORTAL_ROUTER_ADDRESS=your_portal_router_address

# Stargate fee (in basis points, e.g., 100 = 1%)
STARGATE_FEE=100
```

### Deployment

Deploy the Factory contract on your desired network:

```shell
# Deploy on Base
forge script script/Deploy.s.sol --rpc-url $BASE_RPC_URL --broadcast --verify

# Deploy on Arbitrum
forge script script/Deploy.s.sol --rpc-url $ARB_RPC_URL --broadcast --verify

# Deploy on Flow
forge script script/Deploy.s.sol --rpc-url $FLOW_RPC_URL --broadcast --verify
```

### Usage Examples

#### Deploy a Remote Smart Account

```solidity
// Deploy your Remote smart account
address remoteAccount = factory.deploy(msg.sender);
```

#### Cross-Chain DeFi Interaction

```solidity
// Example: Deposit USDC into Aave on Base from any chain
Remote remote = Remote(remoteAccount);

// Prepare cross-chain transfer with DeFi composition
(uint256 valueToSend, SendParam memory sendParam, MessagingFee memory fee) = 
    remote.prepare(
        stargateUSDC,           // Stargate USDC pool
        BASE_CHAIN_EID,         // Destination: Base
        1000 * 1e6,            // Amount: 1000 USDC
        remoteAccount,          // Composer contract
        aaveDepositCalldata,    // Aave deposit transaction
        1000000                 // Gas limit
    );

// Execute the cross-chain transaction
remote.executeStargate{value: valueToSend}(
    stargateUSDC,
    sendParam,
    fee,
    valueToSend
);
```

#### Batch Operations

```solidity
// Execute multiple cross-chain operations in one transaction
address[] memory stargates = [stargateUSDC, stargateETH];
SendParam[] memory params = [usdcParam, ethParam];
MessagingFee[] memory fees = [usdcFee, ethFee];
uint256[] memory values = [usdcValue, ethValue];

remote.executeBatchStargate{value: totalValue}(
    stargates,
    params,
    fees,
    values
);
```

## Development

### Testing

```shell
# Run all tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test file
forge test --match-path test/Remote.t.sol

# Run with gas reporting
forge test --gas-report
```

### Formatting and Linting

```shell
# Format code
forge fmt

# Check formatting
forge fmt --check
```

### Coverage

```shell
# Generate coverage report
forge coverage

# Generate detailed HTML coverage report
forge coverage --report lcov && genhtml lcov.info --output-directory coverage
```

## Security Considerations

- Remote smart accounts inherit Safe's battle-tested security model
- Cross-chain messages are validated through LayerZero's security framework
- All DeFi interactions are executed atomically with proper error handling
- Factory uses CREATE2 for deterministic and secure deployments

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Community

Join our growing community of developers building the future of cross-chain DeFi:

- [GitHub](https://github.com/remote-protocol): Protocol source code and development
- [Discord](https://discord.gg/remote-protocol): Developer community and support
- [Twitter](https://twitter.com/remote_protocol): Latest updates and announcements
- [Documentation](https://docs.remote-protocol.xyz): Comprehensive guides and API reference

## License

This project is licensed under the LGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---

**Built during ETHGlobal Prague Hackathon 2025** 🚀




