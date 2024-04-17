// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnglishAuction {
    address payable public auctioneer;
    uint256 public startTime; // Start time (block number)
    uint256 public endTime;   // End time (block number)

    enum AuctionState { Started, Running, Ended, Cancelled }
    AuctionState public auctionState;

    uint256 public highestBid;
    uint256 public minimumBidIncrement; // Use a more descriptive name

    address payable public highestBidder;

    mapping(address => uint256) public bids;
    address[] public bidderAddresses; // Store bidder addresses separately

    event BidPlaced(address bidder, uint256 bidAmount);

    constructor(uint256 duration) {
        auctioneer = payable(msg.sender);
        auctionState = AuctionState.Running;
        startTime = block.number;
        endTime = startTime + duration;
        minimumBidIncrement = 1 ether;
    }

    modifier notOwner() {
        require(auctioneer != msg.sender, "Not allowed for owner");
        _;
    }

    modifier onlyOwner() {
        require(auctioneer == msg.sender, "Only owner can perform");
        _;
    }

    modifier started() {
        require(block.number > startTime, "Auction not started yet");
        _;
    }

    function cancelAuction() public onlyOwner {
        auctionState = AuctionState.Cancelled;
    }

    function endAuction() public onlyOwner {
        auctionState = AuctionState.Ended;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function placeBid() public payable notOwner started {
        require(auctionState == AuctionState.Running, "Auction not running");
        require(msg.value >= minimumBidIncrement + highestBid, "Bid too low");

        uint256 currentBid = bids[msg.sender] + msg.value;

        bids[msg.sender] = currentBid;
        highestBid = currentBid;

        if (currentBid > bids[highestBidder]) {
            highestBidder = payable(msg.sender);
        }

        emit BidPlaced(msg.sender, currentBid);
    }

    function finalizeAuction() public {
        require(auctionState == AuctionState.Ended || block.number > endTime, "Auction still running");
        require(msg.sender == auctioneer || msg.sender == highestBidder, "Not authorized");

        if (msg.sender == auctioneer) {
            // Refund all bidders except the highest bidder
            for (uint256 i = 0; i < bidderAddresses.length; i++) {
                address bidder = bidderAddresses[i];
                if (bidder != highestBidder) {
                    bids[bidder] = 0; // Reset bid for non-winner
                    payable(bidder).transfer(bids[bidder]);
                }
            }
        } else {
            // Transfer ownership of the item to the highest bidder (implementation omitted)
            auctioneer.transfer(highestBid);
        }

        auctionState = AuctionState.Ended;
        bids[highestBidder] = 0; // Reset bid for the winner
    }

    function withdraw() public {
        require(auctionState == AuctionState.Cancelled || auctionState == AuctionState.Ended || block.number > endTime, "Auction still running");
        require(bids[msg.sender] > 0, "No bids to withdraw");

        address payable person = payable(msg.sender);
        uint256 value = bids[msg.sender];

        if (auctionState == AuctionState.Cancelled) {
            // Refund bids in case of cancellation
        } else {
            require(msg.sender != highestBidder, "Highest bidder cannot withdraw");
        }

        bids[msg.sender] = 0;
        person.transfer(value);
    }
}