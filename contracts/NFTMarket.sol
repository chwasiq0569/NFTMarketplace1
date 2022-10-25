pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct NFTListing {
    uint256 price;
    address seller;
}

contract NFTMarket is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIDs;
    mapping(uint256 => NFTListing) private _listings;


    event NFTTransfer(uint256 tokenID, address to, string tokenURI, uint256 price);

    constructor() ERC721("Wasiq's NFT", "WNFT") { }

    function createNFT(string calldata tokenURI) public  {
        _tokenIDs.increment();
        uint256 currentID = _tokenIDs.current();
        _safeMint(msg.sender, currentID);
        _setTokenURI(currentID, tokenURI);
        emit NFTTransfer(currentID, msg.sender, tokenURI, 0);
    }
    
    function listNFT(uint256 tokenID, uint256 price) public {
        require(price > 0, "NFT Market: price must be greater than 0");
        approve(address(this), tokenID);
        transferFrom(msg.sender, address(this), tokenID);
        _listings[tokenID] = NFTListing(price, msg.sender);
        emit NFTTransfer(tokenID, address(this), "", price);
    }

    function buyNFT(uint256 tokenID) public payable {
        NFTListing memory listing = _listings[tokenID];
        require(listing.price > 0, "NFTMarket: nft not listed for sale");
        require(msg.value == listing.price, "NFTMarket: incorrect price");
        transferFrom(address(this), msg.sender, tokenID);
        payable(msg.sender).transfer(listing.price.mul(95).div(100));
        emit NFTTransfer(tokenID, msg.sender, "", 0);
    }

    function cancelListing(uint256 tokenID) public {
        NFTListing memory listing = _listings[tokenID];
        require(listing.price > 0, "NFTMarket: nft not listed for sale");
        require(listing.seller == msg.sender, "NFTMarket: you are not the owner");
        transferFrom(address(this), msg.sender, tokenID);
        clearListing(tokenID);
        emit NFTTransfer(tokenID, msg.sender, "", 0);
    }

    function withdrawFunds() public onlyOwner{
        uint256 balance = address(this).balance;
        require(balance > 0, "NFTMarket: balance is zero");
        payable(owner()).transfer(balance);
    } 

    function clearListing(uint256 tokenID) private {
        _listings[tokenID].price = 0;
        _listings[tokenID].seller = address(0);
    }
}