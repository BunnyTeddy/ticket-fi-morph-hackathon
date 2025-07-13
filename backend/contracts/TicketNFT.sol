// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract TicketNFT is ERC721Enumerable, ERC721Royalty, Ownable {
    uint256 public immutable ticketPrice;
    uint256 public immutable maxSupply;
    uint256 private _nextTokenId;

    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        uint256 _ticketPrice,
        uint256 _maxSupply,
        address _royaltyReceiver,
        uint96 _royaltyFeeBps
    ) ERC721(name, symbol) Ownable(initialOwner) {
        ticketPrice = _ticketPrice;
        maxSupply = _maxSupply;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeBps);
        _nextTokenId = 1;
    }

    function buyTickets(uint256 quantity) public payable {
        require(totalSupply() + quantity <= maxSupply, "Not enough tickets left");
        require(ticketPrice > 0, "This event is not for sale");
        require(msg.value == ticketPrice * quantity, "Incorrect ETH amount");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;
            _safeMint(msg.sender, tokenId);
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Enumerable, ERC721)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
