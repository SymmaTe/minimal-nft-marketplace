//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NftMarketplace} from "../../src/NftMarketplace.sol";
import {DeployNftMarketplace} from "../../script/DeployNftMarketplace.s.sol";
import {MockERC721} from "../mocks/MockERC721.sol";

contract IntegrationNftMarketplaceTest is Test {
    NftMarketplace public nftMarketplace;
    DeployNftMarketplace public deployer;
    MockERC721 public mockERC721;

    address public buyer = makeAddr("buyer");
    address public seller = makeAddr("seller");
    address public others = makeAddr("others");
    uint256 public constant LISTING_PRICE = 1 ether;
    uint256 public constant TOKEN_ID = 0;

    function setUp() external {
        deployer = new DeployNftMarketplace();
        nftMarketplace = deployer.run();
        mockERC721 = new MockERC721();
        // Mint an NFT to the seller
        mockERC721.mint(seller);
        vm.deal(buyer, 10 ether);
    }

    function testIntegrationListAndCancel() public {
        // Seller approves the marketplace to manage their NFT
        vm.prank(seller);
        mockERC721.approve(address(nftMarketplace), TOKEN_ID);

        // List the item
        vm.prank(seller);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, LISTING_PRICE);

        // Cancel the listing
        vm.prank(seller);
        nftMarketplace.cancelListing(address(mockERC721), TOKEN_ID);

        //assert
        NftMarketplace.Listing memory listing = nftMarketplace.getListing(address(mockERC721), TOKEN_ID);
        assertEq(listing.price, 0);
        assertEq(listing.seller, address(0));
    }

    function testIntegrationListAndBuy() public {
        // Seller approves the marketplace to manage their NFT
        vm.prank(seller);
        mockERC721.approve(address(nftMarketplace), TOKEN_ID);

        // List the item
        vm.prank(seller);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, LISTING_PRICE);

        // Buyer purchases the item
        uint256 fee = LISTING_PRICE / 20; // 5% fee
        uint256 sellerAmount = LISTING_PRICE - fee;
        uint256 ownerInitialBalance = nftMarketplace.i_owner().balance;
        vm.prank(buyer);
        nftMarketplace.buyItem{value: LISTING_PRICE}(address(mockERC721), TOKEN_ID);

        //assert
        address newOwner = mockERC721.ownerOf(TOKEN_ID);
        assertEq(newOwner, buyer);

        NftMarketplace.Listing memory listing = nftMarketplace.getListing(address(mockERC721), TOKEN_ID);
        assertEq(listing.price, 0);
        assertEq(listing.seller, address(0));

        assertEq(address(seller).balance, sellerAmount);
        assertEq(nftMarketplace.i_owner().balance, ownerInitialBalance + fee);
        assertEq(address(buyer).balance, 10 ether - LISTING_PRICE);
    }
}
