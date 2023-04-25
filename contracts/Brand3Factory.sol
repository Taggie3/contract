//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./Brand3Slogan.sol";
import "./interfaces/IBrand3Tag.sol";
import "./Brand3Tag.sol";

contract Brand3Factory {
    mapping(address => uint256) public nonce;
    Brand3Tag brand3Tag;

    Brand3Slogan[] public SloganArray;

    constructor(address payable brand3TagAddress) {
        brand3Tag = Brand3Tag(brand3TagAddress);
    }

    function getNonce(address) external view returns (uint256) {
        return nonce[msg.sender];
    }

    function createNewSlogan(
        uint256 _nonce,
        string memory _signature,
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        string memory _logoUrl,
        uint256[] memory tagIds,
        uint256 _brandId
    ) external {
        for (uint256 i = 0; i < tagIds.length; i++) {
            (uint256 tokenId, , ) = brand3Tag.tokenIdToTag(tagIds[i]);
            require(tokenId == tagIds[i], "invalid tagId");
        }
        if (!checkValidSignature(_signature)) {
            revert InvalidSignature();
        }

        if (_nonce != nonce[msg.sender]) {
            revert InvalidNonce();
        }

        Brand3Slogan brand3Slogan = new Brand3Slogan(
            _baseURI,
            _name,
            _symbol,
            _logoUrl,
            tagIds
        );
        SloganArray.push(brand3Slogan);
        nonce[msg.sender] += 1;

        emit NewBrandEvent(_brandId,address(brand3Slogan), msg.sender);
    }

    function getBrand3Slogan() external view returns (Brand3Slogan[] memory) {
        return SloganArray;
    }

    function checkValidSignature(string memory signature)
        internal
        pure
        returns (bool)
    {
        //        TODO 验证签名实现
        return true;
        // require(keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("Brand3")), "Invalid signature");
    }

    // errors
    error InvalidSignature();
    error InvalidTag();
    error InvalidNonce();
    error ContractAlreadyInitialized();

    // events
    event NewBrandEvent(uint256 brandId, address brandAddress, address owner);
}
