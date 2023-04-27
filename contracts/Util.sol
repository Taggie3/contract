// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TagContract.sol";
import "./BrandContract.sol";

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

    function newBrandContract(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        string memory _slogan,
        TagContract.Tag[] memory tags
    ) public returns (address brandAddress) {
        BrandContract brandContract = new BrandContract(
            _name,
            _symbol,
            _logo,
            _slogan,
            tags
        );
        return address(brandContract);
    }
}
