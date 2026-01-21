//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NftMarketplace is ReentrancyGuard {
    error NftMarketplace__NotApprovedForMarketplace();
    error NftMarketplace__PriceMustBeAboveZero();
    error NftMarketplace__NotOwner();
    error NftMarketplace__NotListed();
    error NftMarketplace__IncorrectPrice();
    error NftMarketplace__NotSeller();

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    address payable public immutable i_owner;

    event ItemListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address seller
    );

    event ItemBought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 fee,
        address buyer
    );

    event ItemCanceled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller
    );

    constructor() {
        i_owner = payable(msg.sender);
    }

    /*Lising Nfts*/
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != msg.sender) {
            revert NftMarketplace__NotOwner();
        }
        if (
            nft.getApproved(tokenId) != address(this) &&
            nft.isApprovedForAll(msg.sender, address(this)) == false
        ) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price
        });
        emit ItemListed(nftAddress, tokenId, price, msg.sender);
    }

    /*Buying Nfts*/
    /*The fee is 5% and is borne by the seller.*/
    function buyItem(
        address nftAddress,
        uint256 tokenId
    ) external payable nonReentrant {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (listedItem.price == 0) {
            revert NftMarketplace__NotListed();
        }
        uint256 fee = listedItem.price / 20;
        uint256 sellerAmount = listedItem.price - fee;
        if (msg.value != listedItem.price) {
            revert NftMarketplace__IncorrectPrice();
        }
        delete s_listings[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );
        (bool success, ) = payable(listedItem.seller).call{value: sellerAmount}(
            ""
        );
        require(success, "Transfer failed");
        if (fee > 0) {
            (bool feeSuccess, ) = i_owner.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }

        emit ItemBought(nftAddress, tokenId, listedItem.price, fee, msg.sender);
    }

    /*Canceling a listing*/
    function cancelListing(address nftAddress, uint256 tokenId) external {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (listedItem.price == 0) {
            revert NftMarketplace__NotListed();
        }
        if (listedItem.seller != msg.sender) {
            revert NftMarketplace__NotSeller();
        }
        delete s_listings[nftAddress][tokenId];
        emit ItemCanceled(nftAddress, tokenId, msg.sender);
    }

    /*Getter functions*/
    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }
}
