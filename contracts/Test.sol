//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./interfaces/IBrandContract.sol";

contract Test {
    function test(address brandAddress) public {
        IBrandContract brandContract = IBrandContract(brandAddress);
        brandContract.transferOwnership(tx.origin);
    }
}
