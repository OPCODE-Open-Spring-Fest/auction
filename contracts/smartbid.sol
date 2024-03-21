// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnglishAuction {
    address payable public auctioneer;
    uint256 public stblock;   // start time
    uint256 public etblock;   // end time

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
    
    function cancelAuc() public Owner{
        auctionState=Auc_state.Cancelled;
    }

    function endAuc() public Owner{
        auctionState=Auc_state.Ended;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) 
        return a;
        else 
        return b;
    }

    function AddBid() payable public NotOwner Start {
        require(auctionState == Auc_state.Running);
        require(msg.value >= 1 ether);
        uint256 currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestPayable);

        bids[msg.sender] = currentBid;

        if (currentBid < bids[highestBidder]) {
            highestPayable = min(currentBid + bidInc, bids[highestBidder]);
        }
        else {
            highestPayable=min(currentBid, bids[highestBidder] + bidInc);
            highestBidder=payable(msg.sender);
        }

    }

    function finalizeAuc() public {
        require(auctionState==Auc_state.Cancelled || auctionState==Auc_state.Ended || block.number>etblock);
        require(msg.sender==auctioneer || bids[msg.sender]>0);
        
        address payable person;
        uint value;

        if(auctionState==Auc_state.Cancelled)
        {
            person=payable(msg.sender);
            value=bids[msg.sender];

        }
        else {
            if(msg.sender== auctioneer)
            {
                person=auctioneer;
                value=highestPayable;
            }
            else {
                if(msg.sender ==highestBidder)
                {
                    person=highestBidder;
                    value=bids[highestBidder];
                }
                else{
                    person=payable(msg.sender);
                    value=bids[msg.sender];
                }
            }
        }
        bids[msg.sender]=0;
        person.transfer(value);
    }
}
