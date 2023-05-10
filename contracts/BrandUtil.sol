// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TagContract.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IBrandUtil.sol";

contract BrandUtil is Initializable, IBrandUtil {
    address public constant brand3Admin =
        address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);

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

    function getDefaultSplitter()
        public
        returns (PaymentSplitter paymentSplitter)
    {
        if (tx.origin == brand3Admin) {
            address[] memory tempPayees = new address[](1);
            uint256[] memory tempShares = new uint256[](1);
            tempPayees[0] = tx.origin;
            tempShares[0] = 200;
            return
                new PaymentSplitter(tempPayees, tempShares);
        }
        address[] memory payees = new address[](2);
        uint256[] memory shares = new uint256[](2);
        payees[0] = tx.origin;
        shares[0] = 200;

        payees[1] = brand3Admin;
        shares[1] = 50;

        return new PaymentSplitter(payees, shares);
    }

    function getSplitter(address owner, address creator)
        public
        returns (PaymentSplitter paymentSplitter)
    {
        if (owner == brand3Admin && creator == brand3Admin) {
            address[] memory tempPayees = new address[](1);
            uint256[] memory tempShares = new uint256[](1);
            tempPayees[0] = owner;
            tempShares[0] = 100;
            return
                new PaymentSplitter(tempPayees, tempShares);
        }

        if (owner == brand3Admin || creator == brand3Admin) {
            address[] memory tempPayees = new address[](2);
            uint256[] memory tempShares = new uint256[](2);
            if (owner != brand3Admin) {
                tempPayees[0] = owner;
            }
            if (creator != brand3Admin) {
                tempPayees[0] = creator;
            }
            tempShares[0] = 100;
            tempPayees[1] = brand3Admin;
            tempShares[1] = 150;
            return
                new PaymentSplitter(tempPayees, tempShares);
        }

        if (owner == creator) {
            address[] memory tempPayees = new address[](2);
            uint256[] memory tempShares = new uint256[](2);
            tempPayees[0] = owner;
            tempShares[0] = 200;
            tempPayees[1] = brand3Admin;
            tempShares[1] = 150;
            return
                new PaymentSplitter(tempPayees, tempShares);
        }

        address[] memory payees = new address[](3);
        uint256[] memory shares = new uint256[](3);
        payees[0] = owner;
        shares[0] = 100;
        payees[1] = creator;
        shares[1] = 100;
        payees[2] = brand3Admin;
        shares[2] = 50;

        return new PaymentSplitter(payees, shares);
    }

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
