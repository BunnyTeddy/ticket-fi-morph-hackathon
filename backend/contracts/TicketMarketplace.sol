// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract TicketMarketplace is ReentrancyGuard {
    struct ActiveListing {
        uint256 listingId;
        address seller;
        address ticketContract;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    uint256 private _listingCounter;
    mapping(uint256 => ActiveListing) public listings;
    uint256[] public activeListingIds;

    // ---- [SỬA LỖI] ---- Giảm số lượng tham số indexed xuống còn 3
    event ItemListed(uint256 indexed listingId, address indexed seller, address indexed ticketContract, uint256 tokenId, uint256 price);
    event ItemBought(uint256 indexed listingId, address indexed buyer, address indexed ticketContract, uint256 tokenId, uint256 price);
    event ItemUnlisted(uint256 indexed listingId, address indexed seller, address indexed ticketContract, uint256 tokenId);

    function listItem(address ticketContract, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "Price must be > 0");
        IERC721 ticket = IERC721(ticketContract);
        require(ticket.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(ticket.getApproved(tokenId) == address(this), "Marketplace not approved");

        _listingCounter++;
        uint256 listingId = _listingCounter;

        listings[listingId] = ActiveListing(
            listingId,
            msg.sender,
            ticketContract,
            tokenId,
            price,
            true
        );
        activeListingIds.push(listingId);

        emit ItemListed(listingId, msg.sender, ticketContract, tokenId, price);
    }

    function buyItem(uint256 listingId) external payable nonReentrant {
        ActiveListing storage listing = listings[listingId];
        require(listing.isActive, "Item not listed for sale");
        require(msg.value == listing.price, "Incorrect price sent");

        listing.isActive = false; // Đánh dấu là không hoạt động nữa

        (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(listing.ticketContract).royaltyInfo(listing.tokenId, listing.price);
        uint256 sellerProceeds = listing.price - royaltyAmount;

        (bool s1, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
        require(s1, "Royalty payment failed");
        (bool s2, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(s2, "Seller payment failed");

        IERC721(listing.ticketContract).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        emit ItemBought(listingId, msg.sender, listing.ticketContract, listing.tokenId, listing.price);
    }

    function unlistItem(uint256 listingId) external {
        ActiveListing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "You are not the lister");
        require(listing.isActive, "Listing is not active");
        listing.isActive = false;
        emit ItemUnlisted(listingId, msg.sender, listing.ticketContract, listing.tokenId);
    }

    function getActiveListings() public view returns (ActiveListing[] memory) {
        uint256 activeCount = 0;
        for (uint i = 0; i < activeListingIds.length; i++) {
            if (listings[activeListingIds[i]].isActive) {
                activeCount++;
            }
        }

        ActiveListing[] memory result = new ActiveListing[](activeCount);
        uint256 resultIndex = 0;
        for (uint i = 0; i < activeListingIds.length; i++) {
            if (listings[activeListingIds[i]].isActive) {
                result[resultIndex] = listings[activeListingIds[i]];
                resultIndex++;
            }
        }
        return result;
    }
}
