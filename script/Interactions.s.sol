//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NftMarketplace} from "../src/NftMarketplace.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract ListNftMarketplace is Script {
    address public constant NFT_CONTRACT = 0x09a844845483433557D8d3E38f264440DFFEECAB;//Change to your deployed NFT contract address
    uint256 public constant TOKEN_ID = 0;//Change to your minted token ID
    uint256 public constant LISTING_PRICE = 0.005 ether;//Change to your desired listing price


    function run() external {
        address nftMarketplaceAddress = DevOpsTools.get_most_recent_deployment(
            "NftMarketplace",
            block.chainid
        );
        listNft(nftMarketplaceAddress, 
            NFT_CONTRACT,
            TOKEN_ID,
            LISTING_PRICE
        );
    }

    function listNft(address nftMarketplaceAddress, address nftAddress, uint256 tokenId, uint256 price) public {
        vm.startBroadcast();
        NftMarketplace(nftMarketplaceAddress).listItem(
            nftAddress,
            tokenId,
            price
        );
        vm.stopBroadcast();
    }
}

contract CancelNftListing is Script {
    address public constant NFT_CONTRACT = 0x09a844845483433557D8d3E38f264440DFFEECAB;//Change to your deployed NFT contract address
    uint256 public constant TOKEN_ID = 0;//Change to your minted token ID

    function run() external {
        address nftMarketplaceAddress = DevOpsTools.get_most_recent_deployment(
            "NftMarketplace",
            block.chainid
        );
        cancelListing(nftMarketplaceAddress, 
            NFT_CONTRACT,
            TOKEN_ID
        );
    }
    function cancelListing(address nftMarketplaceAddress, address nftAddress, uint256 tokenId) public {
        vm.startBroadcast();
        NftMarketplace(nftMarketplaceAddress).cancelListing(
            nftAddress,
            tokenId
        );
        vm.stopBroadcast();
    }
}