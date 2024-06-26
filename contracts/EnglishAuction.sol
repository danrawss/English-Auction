// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./NFT.sol";

contract EnglishAuction {
    event Start();
    event End(address highestBidder, uint256 highestBid);
    event Bid(address indexed bidder, uint256 bid);
    event WithDraw(address indexed bidder, uint256 amount);

    IERC721 public nft;
    uint256 public nftId;

    address payable public seller;
    bool public started;
    bool public ended;
    uint256 public endAt;

    uint256 public highestBid;
    address public highestBidder;
    mapping (address => uint256) public bids;

    constructor (address _nft, uint256 _nftId, uint256 _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        highestBid = _startingBid;
        seller = payable(msg.sender);
    }

    function start() external {
        require(!started, "Already started");
        require(msg.sender == seller, "You are not the seller");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp + 60;
        
        emit Start();
    }

    function end() external {
        require(started, "Need to start first");
        require(block.timestamp >= endAt, "Auction is still going");
        require(!ended, "Auction has already finished");

        if (highestBidder != address(0)) {          
            (bool sent, ) = seller.call{value: highestBid}("");
            require(sent, "Failed to send Ether to seller");

            nft.transferFrom(address(this), highestBidder, nftId);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        ended = true;

        emit End(highestBidder, highestBid);
    }

    function bid() external payable {
        require(started, "Not started yet");
        require(block.timestamp < endAt, "Auction ended");
        require(msg.value > highestBid, "Value < Highest Bid");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external payable {
        uint256 bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit WithDraw(msg.sender, bal);
    }
}