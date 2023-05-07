// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IIPContract {
    function brandAddress() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}
