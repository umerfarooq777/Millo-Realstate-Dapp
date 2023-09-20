// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateEscrow is ERC721Enumerable, Ownable {
    // Struct to represent a real estate property
    struct RealEstateProperty {
        string propertyAddress;
        uint256 price;
        address seller;
        bool isListed;
        bool isSold;
    }

    // Mapping from token ID to real estate property
    mapping(uint256 => RealEstateProperty) public properties;

    // Token ID counter
    uint256 private tokenIdCounter = 1;

    // Events
    event PropertyListed(
        uint256 tokenId,
        string propertyAddress,
        uint256 price
    );
    event PropertySold(uint256 tokenId, address buyer);

    constructor() ERC721("RealEstateNFT", "RE") {}

    // Function to list a real estate property
    function listProperty(
        string memory propertyAddress,
        uint256 price
    ) external {
        require(!_exists(tokenIdCounter), "Token already exists");
        _mint(msg.sender, tokenIdCounter);
        properties[tokenIdCounter] = RealEstateProperty({
            propertyAddress: propertyAddress,
            price: price,
            seller: msg.sender,
            isListed: true,
            isSold: false
        });
        emit PropertyListed(tokenIdCounter, propertyAddress, price);
        tokenIdCounter++;
    }

    // Function to buy a listed property
    function buyProperty(uint256 tokenId) external payable {
        RealEstateProperty storage property = properties[tokenId];
        require(property.isListed, "Property not listed");
        require(!property.isSold, "Property already sold");
        require(msg.value >= property.price, "Insufficient funds");

        // Transfer ownership and funds
        _transfer(property.seller, msg.sender, tokenId);
        property.isListed = false;
        property.isSold = true;

        // Send funds to the seller
        payable(property.seller).transfer(msg.value);

        emit PropertySold(tokenId, msg.sender);
    }

    // Function to cancel a listing
    function cancelListing(uint256 tokenId) external {
        RealEstateProperty storage property = properties[tokenId];
        require(property.seller == msg.sender, "Only seller can cancel");
        require(property.isListed, "Property not listed");
        require(!property.isSold, "Property already sold");

        // Transfer the NFT back to the seller
        _transfer(msg.sender, address(this), tokenId);
        property.isListed = false;

        emit PropertyListed(tokenId, property.propertyAddress, property.price);
    }
}
