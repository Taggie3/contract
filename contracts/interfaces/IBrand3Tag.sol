// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBrand3Tag {
    function mint(string memory tagValue, uint16 sortLevel) external;

    function getTagById(uint256 tokenId) external view  returns (string memory);
}
