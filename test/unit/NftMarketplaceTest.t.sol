//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NftMarketplace} from "../../src/NftMarketplace.sol";
import {DeployNftMarketplace} from "../../script/DeployNftMarketplace.s.sol";
import {MockERC721} from "../mocks/MockERC721.sol";

contract NftMarketplaceTest is Test {
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

    modifier getApproval() {
        // Seller approves the marketplace to manage their NFT
        vm.prank(seller);
        mockERC721.approve(address(nftMarketplace), TOKEN_ID);
        _;
    }

    modifier listedItem() {
        // List the item before executing the test
        vm.prank(seller);
        mockERC721.approve(address(nftMarketplace), TOKEN_ID);
        vm.prank(seller);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, LISTING_PRICE);
        _;
    }

    /* Listing Items Tests */
    function testListingItemRevertsIfNotOwner() public getApproval {
        // Test listing an item reverts if the caller is not the owner
        vm.prank(others);
        vm.expectRevert(NftMarketplace.NftMarketplace__NotOwner.selector);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, LISTING_PRICE);
    }

    function testListingItemRevertsIfPriceZero() public getApproval {
        // Test listing an item reverts if the price is zero
        vm.prank(seller);
        vm.expectRevert(NftMarketplace.NftMarketplace__PriceMustBeAboveZero.selector);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, 0);
    }

    function testListingItemRevertsIfDontGetApproval() public {
        // Test listing an item reverts if the marketplace is not approved
        vm.prank(seller);
        vm.expectRevert(NftMarketplace.NftMarketplace__NotApprovedForMarketplace.selector);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, LISTING_PRICE);
    }

    function testListingItemAndEvents() public getApproval {
        // Test successful listing of an item
        vm.expectEmit(true, true, false, true);
        emit NftMarketplace.ItemListed(address(mockERC721), TOKEN_ID, LISTING_PRICE, seller);
        vm.prank(seller);
        nftMarketplace.listItem(address(mockERC721), TOKEN_ID, LISTING_PRICE);
        //assert listing
        NftMarketplace.Listing memory listing = nftMarketplace.getListing(address(mockERC721), TOKEN_ID);
        assert(listing.price == LISTING_PRICE);
        assert(listing.seller == seller);
    }

    /* Buying Items Tests */
    function testBuyingItemRevertsIfNotListed() public listedItem {
        // Test buying an item reverts if it is not listed
        vm.prank(buyer);
        vm.expectRevert(NftMarketplace.NftMarketplace__NotListed.selector);
        nftMarketplace.buyItem(address(mockERC721), TOKEN_ID + 1);
    }

    function testBuyingItemRevertsIncorrectPrice() public listedItem {
        // Test buying an item reverts if the sent value is incorrect
        vm.prank(buyer);
        vm.expectRevert(NftMarketplace.NftMarketplace__IncorrectPrice.selector);
        nftMarketplace.buyItem{value: LISTING_PRICE - 0.1 ether}(address(mockERC721), TOKEN_ID);
    }

    function testBuyingItemAndEvents() public listedItem {
        // Test successful buying of an item
        uint256 fee = LISTING_PRICE / 20;
        uint256 sellerAmount = LISTING_PRICE - fee;
        uint256 ownerInitialBalance = nftMarketplace.i_owner().balance;

        vm.expectEmit(true, true, false, true);
        emit NftMarketplace.ItemBought(address(mockERC721), TOKEN_ID, LISTING_PRICE, fee, buyer);

        vm.prank(buyer);
        nftMarketplace.buyItem{value: LISTING_PRICE}(address(mockERC721), TOKEN_ID);

        // Assert new owner
        assert(mockERC721.ownerOf(TOKEN_ID) == buyer);
        // Assert seller received funds
        assert(address(seller).balance == sellerAmount);
        // Assert marketplace owner received fee
        assert(nftMarketplace.i_owner().balance == fee + ownerInitialBalance);
    }

    /* Canceling Listings Tests */
    function testCancelingListingRevertsNotListed() public {
        // Test canceling a listing reverts if the item is not listed
        vm.prank(seller);
        vm.expectRevert(NftMarketplace.NftMarketplace__NotListed.selector);
        nftMarketplace.cancelListing(address(mockERC721), TOKEN_ID);
    }

    function testCancelingListingRevertsIfNotSeller() public listedItem {
        // Test canceling a listing reverts if the caller is not the seller
        vm.prank(others);
        vm.expectRevert(NftMarketplace.NftMarketplace__NotSeller.selector);
        nftMarketplace.cancelListing(address(mockERC721), TOKEN_ID);
    }

    function testCancelingListingAndEvents() public listedItem {
        // Test successful canceling of a listing
        vm.expectEmit(true, true, false, true);
        emit NftMarketplace.ItemCanceled(address(mockERC721), TOKEN_ID, seller);

        vm.prank(seller);
        nftMarketplace.cancelListing(address(mockERC721), TOKEN_ID);

        // Assert listing is removed
        NftMarketplace.Listing memory listing = nftMarketplace.getListing(address(mockERC721), TOKEN_ID);
        assert(listing.price == 0);
        assert(listing.seller == address(0));
    }
}
