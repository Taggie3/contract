// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../TagContract.sol";

interface IBrandContract {
    function brandSetAddress() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function owner() external view returns (address);

    function listTags() external view returns (TagContract.Tag[] memory);

    function transferOwnership(address newOwner) external;

    function updateBrandSetId(uint256 _brandSetId) external;
}
