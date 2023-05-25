// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../TagContract.sol";
import "../PaySplitter.sol";

interface IBrandUtil {
    // function tagIdsToTags(uint256[] memory tagIds, TagContract tagContract)
    // external
    // view
    // returns (TagContract.Tag[] memory tags);

    function getDefaultSplitter()
        external
        returns (PaySplitter paymentSplitter);

    function getSplitter(address owner, address creator)
        external
        returns (PaySplitter paymentSplitter);

    function getMessageHash(string memory message)
        external
        pure
        returns (bytes32);

    function checkValidSignature(
        bytes memory signature,
        string memory message,
        address signer
    ) external view returns (bool);
}
