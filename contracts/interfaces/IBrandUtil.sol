// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IPaySplitter.sol";
import "./IERC6551Registry.sol";
import "./IERC6551Account.sol";

interface IBrandUtil {
    function getBrand3Admin() external view returns (address);

    function buildSplitter(
        address[] memory payees,
        uint256[] memory shares,
        address owner
    ) external returns (IPaySplitter paySplitter);

    function getMessageHash(string memory message)
        external
        pure
        returns (bytes32);

    function checkValidSignature(
        bytes memory signature,
        string memory message,
        address signer
    ) external view returns (bool);

    function checkTokenBoundAccount(
        address signer,
        address nftAddress,
        uint256 tokenId
    ) external view returns (bool);

    function createTokenBoundAccount(address nftAddress, uint256 tokenId)
        external
        returns (address);
}
