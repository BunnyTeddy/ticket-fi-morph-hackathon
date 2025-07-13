// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TicketNFT.sol";

contract EventManager {
    struct EventInfo {
        string name;
        string symbol;
        address ticketContract;
        address creator;
    }
    EventInfo[] public events;

    event EventCreated(uint256 indexed eventId, string name, address indexed ticketContract, address indexed creator);

    function createEvent(
        string memory name,
        string memory symbol,
        uint256 ticketPrice,
        uint256 maxSupply,
        address royaltyReceiver,
        uint96 royaltyFeeBps
    ) external {
        TicketNFT newTicketContract = new TicketNFT(
            msg.sender, name, symbol, ticketPrice, maxSupply, royaltyReceiver, royaltyFeeBps
        );
        uint256 eventId = events.length;
        events.push(EventInfo(name, symbol, address(newTicketContract), msg.sender));
        emit EventCreated(eventId, name, address(newTicketContract), msg.sender);
    }

    // ---- [SỬA LỖI] ---- Thêm hàm getter để lấy tổng số sự kiện
    function getEventsCount() public view returns (uint256) {
        return events.length;
    }
}

