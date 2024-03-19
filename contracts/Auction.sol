// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnglishAuction {
    address payable public auctioneer;
    uint256 public stblock; // start time
    uint256 public etblock; // end time

    enum Auc_state {
        Started,
        Running,
        Ended,
        Cancelled
    }
    Auc_state public auctionState;

    uint256 public highestBid;
    uint256 public highestPayable;
    uint256 public bidInc;

    address payable public highestBidder;

    mapping(address => uint256) public bids;

    constructor() {
        auctioneer = payable(msg.sender);
        auctionState = Auc_state.Running;
        stblock = block.number;
        etblock = stblock + 240;
        bidInc = 1 ether;
    }

    

    modifier NotOwner() {
        require(auctioneer != msg.sender);
        _;
    }
    modifier Owner() {
        require(auctioneer == msg.sender);
        _;
    }
    modifier Start() {
        require(block.number > stblock, "Not yet Started");
        _;
    }
    modifier beforeEnd() {
        require(block.number < etblock, "Auction is Ended");
        _;
    }
    function cancelAuc() public Owner{
        auctionState=Auc_state.Cancelled;
    }

    function endAuc() public Owner{
        auctionState=Auc_state.Ended;
    }

    
    function AddBid() payable public NotOwner Start beforeEnd {
        // your body of the code will go here

    }

    function finalizeAuc() public {
        // your body of the code will go here
    }
}
