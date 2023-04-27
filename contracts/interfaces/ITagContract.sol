// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITagContract {
    struct Tag {
        uint256 tokenId;
        string types;
        //tag的内容
        string value;
    }

    function getTag(uint256 tokenId) external view returns (Tag memory);
}
