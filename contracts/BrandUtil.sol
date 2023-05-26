// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TagContract.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IBrandUtil.sol";
import "./PaySplitter.sol";

contract BrandUtil is Initializable, IBrandUtil {

    //    function tagIdsToTags(uint256[] memory tagIds, TagContract tagContract)
    //        public
    //        view
    //        returns (TagContract.Tag[] memory tags)
    //    {
    //        tags = new TagContract.Tag[](tagIds.length);
    //        for (uint256 i = 0; i < tagIds.length; i++) {
    //            uint256 tagId = tagIds[i];
    //            TagContract.Tag memory tag = tagContract.getTag(tagId);
    //            tags[i] = tag;
    //        }
    //        return tags;
    //    }
//    function getDefaultSplitter()
//    public
//    returns (PaySplitter paySplitter)
//    {
//
//        address[] memory payees = new address[](2);
//        uint256[] memory shares = new uint256[](2);
//        payees[0] = tx.origin;
//        shares[0] = 200;
//
//        payees[1] = brand3Admin;
//        shares[1] = 50;
//
//        return new PaySplitter(payees, shares);
//    }
//
//    function getSplitter(address owner, address creator)
//    public
//    returns (PaySplitter paySplitter)
//    {
//
//        address[] memory payees = new address[](3);
//        uint256[] memory shares = new uint256[](3);
//        payees[0] = owner;
//        shares[0] = 100;
//        payees[1] = creator;
//        shares[1] = 100;
//        payees[2] = brand3Admin;
//        shares[2] = 50;
//
//        return new PaySplitter(payees, shares);
//    }

    function getMessageHash(string memory message)
    public
    pure
    returns (bytes32)
    {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                StringsUpgradeable.toString(bytes(message).length),
                bytes(message)
            )
        );

        return messageHash;
    }

    function checkValidSignature(
        bytes memory signature,
        string memory message,
        address signer
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(message);
        return
        SignatureCheckerUpgradeable.isValidSignatureNow(
            signer,
            messageHash,
            signature
        );
    }
}
