pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT

interface ILetterboxV3 {
    event StampCreated(uint256 indexed tokenId);
    event LetterboxCreated(uint256 indexed tokenId);
    event LetterboxStamped();
    event LetterboxCollected();

    function mintStamp(address to_, string memory uri_) public payable;

    function mintLetterbox(address to_, string memory uri_) public;

    function stampToLetterbox(
        address stampUser,
        uint256 letterboxTokenId,
        bool accepted
    ) public;

    function letterboxToStamp(address stampUser, uint256 letterboxTokenId)
        public;
}
