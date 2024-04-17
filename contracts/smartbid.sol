// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EnglishAuction is ERC721, Ownable {
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

    event bidPlaced (address bidder, uint bidAmount);

    constructor(address initialOwner) ERC721("EnglishAuction", "EA") Ownable(initialOwner) {
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

    modifier Start() {
        require(block.number > stblock, "Not yet Started");
        _;
    }
    
    function cancelAuc() public onlyOwner {
        auctionState=Auc_state.Cancelled;
    }

    function endAuc() public onlyOwner {
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

        emit bidPlaced(msg.sender, currentBid);
    }

    function finalizeAuc() public {
        require(auctionState==Auc_state.Ended || block.number>etblock, "Auction still running");
        require(msg.sender==auctioneer || msg.sender == highestBidder, "Call withdraw to withdraw your eth back");
        
        address payable person;
        uint value;

            if(msg.sender== auctioneer)
            {
                person=auctioneer;
                value=highestPayable;
            }
            else {
                //if(msg.sender == highestBidder)
                    // ownership of the bought item should transfer here
                }

            bids[msg.sender]=0;
            person.transfer(value);
        }

    function withdraw() public {
        require(auctionState==Auc_state.Cancelled || auctionState==Auc_state.Ended || block.number>etblock, "Auction still running");
        require(bids[msg.sender]>0, "Only bidders can withdraw");

        address payable person;
        uint value;

        if(auctionState==Auc_state.Cancelled){
            person=payable(msg.sender);
            value=bids[msg.sender];
        }else{
            require(msg.sender!=highestBidder, "Highest bidder cannot withdraw");
                person=payable(msg.sender);
                value=bids[msg.sender];               
            }
        bids[msg.sender]=0;
        person.transfer(value);            
    }  

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function transferNFT(address from, address to, uint256 tokenId) public onlyOwner {
        require(ownerOf(tokenId) == from, "You don't own this token");
        safeTransferFrom(from, to, tokenId);
    }
}