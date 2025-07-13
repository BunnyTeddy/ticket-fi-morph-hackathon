// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TicketBNPL is ReentrancyGuard {
    struct Deposit {
        uint256 depositId;
        address buyer;
        address seller;
        address ticketContract;
        uint256 tokenId;
        uint256 depositAmount;
        uint256 remainingAmount;
        uint256 deadline;
        bool isActive;
    }

    uint256 private _depositCounter;
    mapping(uint256 => Deposit) public deposits;

    event TicketDeposited(uint256 indexed depositId, address indexed buyer, address indexed seller, address ticketContract, uint256 tokenId, uint256 depositAmount);
    event PaymentCompleted(uint256 indexed depositId, address indexed buyer);
    event DepositReclaimed(uint256 indexed depositId, address indexed seller);

    // Giả sử tỷ lệ đặt cọc là 30%
    uint256 public constant DEPOSIT_BPS = 3000; // 3000 basis points = 30%

    function makeDeposit(address ticketContract, uint256 tokenId, uint256 fullPrice) external payable nonReentrant {
        uint256 requiredDeposit = (fullPrice * DEPOSIT_BPS) / 10000;
        require(msg.value == requiredDeposit, "Incorrect deposit amount");

        IERC721 ticket = IERC721(ticketContract);
        address seller = ticket.ownerOf(tokenId);
        require(ticket.getApproved(tokenId) == address(this), "BNPL contract not approved");

        // Chuyển vé vào contract escrow
        ticket.safeTransferFrom(seller, address(this), tokenId);

        _depositCounter++;
        uint256 depositId = _depositCounter;

        deposits[depositId] = Deposit({
            depositId: depositId,
            buyer: msg.sender,
            seller: seller,
            ticketContract: ticketContract,
            tokenId: tokenId,
            depositAmount: msg.value,
            remainingAmount: fullPrice - msg.value,
            deadline: block.timestamp + 14 days, // Hạn chót là 14 ngày
            isActive: true
        });

        emit TicketDeposited(depositId, msg.sender, seller, ticketContract, tokenId, msg.value);
    }

    function completePayment(uint256 depositId) external payable nonReentrant {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(msg.sender == deposit.buyer, "Only the buyer can complete payment");
        require(block.timestamp < deposit.deadline, "Deadline has passed");
        require(msg.value == deposit.remainingAmount, "Incorrect remaining amount");

        deposit.isActive = false;

        // Chuyển toàn bộ số tiền cho người bán
        (bool success, ) = payable(deposit.seller).call{value: deposit.depositAmount + deposit.remainingAmount}("");
        require(success, "Payment to seller failed");

        // Chuyển vé cho người mua
        IERC721(deposit.ticketContract).safeTransferFrom(address(this), deposit.buyer, deposit.tokenId);

        emit PaymentCompleted(depositId, msg.sender);
    }

    function reclaimTicket(uint256 depositId) external nonReentrant {
        Deposit storage deposit = deposits[depositId];
        require(deposit.isActive, "Deposit not active");
        require(msg.sender == deposit.seller, "Only the seller can reclaim");
        require(block.timestamp >= deposit.deadline, "Deadline has not passed yet");

        deposit.isActive = false;

        // Người bán lấy lại vé, và được hưởng tiền cọc
        (bool success, ) = payable(deposit.seller).call{value: deposit.depositAmount}("");
        require(success, "Deposit transfer to seller failed");

        IERC721(deposit.ticketContract).safeTransferFrom(address(this), deposit.seller, deposit.tokenId);

        emit DepositReclaimed(depositId, msg.sender);
    }
}
