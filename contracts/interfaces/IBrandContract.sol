// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../TagContract.sol";

interface IBrandContract {
    function brandSetAddress() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function owner() external view returns (address);

    function listTags() external view returns (TagContract.Tag[] memory);

    function transferOwnership(address newOwner) external;
}
