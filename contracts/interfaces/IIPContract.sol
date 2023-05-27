// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IIPContract {
    function brandContract() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function updateBrandOwner(address newBrandOwner) external;
}
