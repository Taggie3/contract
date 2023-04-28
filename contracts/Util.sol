// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TagContract.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

library Util {
    function checkValidSignature(string memory signature)
        public
        pure
        returns (bool)
    {
        //        TODO 验证签名实现
        return true;
        // require(keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("Brand3")), "Invalid signature");
    }

    function tagIdsToTags(uint256[] memory tagIds, TagContract tagContract)
        public
        view
        returns (TagContract.Tag[] memory tags)
    {
        tags = new TagContract.Tag[](tagIds.length);
        for (uint256 i = 0; i < tagIds.length; i++) {
            uint256 tagId = tagIds[i];
            TagContract.Tag memory tag = tagContract.getTag(tagId);
            tags[i] = tag;
        }
        return tags;
    }

    function getDefaultSplitter() public returns (address splitterAddress) {
        address[] memory payees = new address[](2);
        payees[0] = tx.origin;
        payees[1] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
        uint256[] memory shares = new uint256[](2);
        shares[0] = 200;
        shares[1] = 50;
        PaymentSplitter paymentSplitter = new PaymentSplitter{value: msg.value}(
            payees,
            shares
        );
        return address(paymentSplitter);
    }

    function getSplitter(address owner, address creator)
        public
        returns (address splitterAddress)
    {
        address[] memory payees = new address[](3);
        payees[0] = owner;
        payees[1] = creator;
        payees[2] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
        uint256[] memory shares = new uint256[](3);
        shares[0] = 100;
        shares[1] = 100;
        shares[2] = 50;
        PaymentSplitter paymentSplitter = new PaymentSplitter{value: msg.value}(
            payees,
            shares
        );
        return address(paymentSplitter);
    }
}
