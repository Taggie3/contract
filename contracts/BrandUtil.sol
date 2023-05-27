// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IBrandUtil.sol";
import "./PaySplitter.sol";

contract BrandUtil is Initializable, IBrandUtil {
    address public brand3Admin;
    PaySplitter[] public splitters;

    function initialize() public initializer {
        brand3Admin = msg.sender;
    }

    function setBrand3Admin(address newBrand3Admin) public {
        require(msg.sender == brand3Admin, "BrandUtil: Only brand3Admin can set brand3Admin");
        for (uint256 i = 0; i < splitters.length; i++) {
            splitters[i].deletePayee(brand3Admin);
            splitters[i].addPayee(newBrand3Admin, 100);
        }
        brand3Admin = newBrand3Admin;
    }

    function getBrand3Admin() public view returns (address) {
        return brand3Admin;
    }

    function buildSplitter(address[] memory payees, uint256[] memory shares, address owner)
    public
    returns (IPaySplitter paySplitter)
    {
        // 配置默认版权分账
        PaySplitter newPaySplitter = new PaySplitter(payees, shares, owner);
        splitters.push(newPaySplitter);
        return newPaySplitter;
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
