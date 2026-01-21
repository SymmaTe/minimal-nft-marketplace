# Minimal NFT Marketplace (Foundry + Solidity)

A super minimal, secure, and gas-efficient NFT marketplace built with Foundry.  
Perfect for learning, portfolio projects, or as a starting point for more complex marketplaces.

**Live on Sepolia Testnet**  
Contract Address: `0xAa656A66709F367E51D26fB353B390aF8629699F`  
Etherscan: `https://sepolia.etherscan.io/address/0xAa656A66709F367E51D26fB353B390aF8629699F`

## Features

- List any ERC721 NFT for sale  
- Buy listed NFTs with ETH  
- Cancel your own listings  
- Reentrancy protected (`ReentrancyGuard`)  
- Full unit + integration (fork) testing with Foundry  
- 100% open-source & verified on Etherscan  
- A 5% platform fee is charged to sellers

## Smart Contract

`src/NftMarketplace.sol`

- Uses OpenZeppelin ERC721 interface & ReentrancyGuard
- Simple mapping-based storage: `nftAddress => tokenId => Listing`
- Events: `ItemListed`, `ItemBought`, `ItemCanceled`
- Proper approval checks before listing
- ETH directly transferred to seller on purchase

## Quick Start

### Prerequisites
- Foundry installed (`forge`)
- Node.js (optional, for frontend)

### Installation

```bash
git clone https://github.com/SymmaTe/minimal-nft-marketplace.git
cd minimal-nft-marketplace
forge install
```

## Remind
- Don't forget to first get your NFT contract to approve to authorize the contract

