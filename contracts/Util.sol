// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Util {
    function checkValidSignature(string memory signature)
    internal
    pure
    returns (bool)
    {
        //        TODO 验证签名实现
        return true;
        // require(keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("Brand3")), "Invalid signature");
    }
}
