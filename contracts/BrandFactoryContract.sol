//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./BrandContract.sol";
import "./TagContract.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BrandFactoryContract is Ownable, Pausable {
    mapping(address => uint256) public nonce;
    TagContract public tagContract;

    struct Brand {
        string name;
        string symbol;
        BrandContract BrandContract;
    }

    Brand[] public brands;

    constructor(address payable tagContractAddress) {
        tagContract = TagContract(tagContractAddress);
    }

    function changeTagContract(address payable tagContractAddress)
        public
        onlyOwner
    {
        tagContract = TagContract(tagContractAddress);
    }

    function getNonce(address) external view returns (uint256) {
        return nonce[msg.sender];
    }

    function createNewBrand(
        uint256 _nonce,
        string memory _signature,
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        string memory _logo,
        string memory _slogan,
        uint256[] memory tagIds
    ) external whenNotPaused {
        // 检查brand是否已存在
        for (uint256 i = 0; i < brands.length; i++) {
            Brand memory brand = brands[i];
            require(
                keccak256(bytes(brand.name)) != keccak256(bytes(_name)),
                "brand name existed"
            );
        }

        if (!checkValidSignature(_signature)) {
            revert InvalidSignature();
        }

        if (_nonce != nonce[msg.sender]) {
            revert InvalidNonce();
        }

        TagContract.Tag[] memory tags = new TagContract.Tag[](tagIds.length);
        for (uint256 i = 0; i < tagIds.length; i++) {
            uint256 tagId = tagIds[i];
            (
                uint256 tokenId,
                string memory types,
                string memory value
            ) = tagContract.tags(tagId);
            TagContract.Tag memory tag = TagContract.Tag(tokenId, types, value);
            tags[i] = tag;
        }

        BrandContract brandContract = new BrandContract(
            _baseURI,
            _name,
            _symbol,
            _logo,
            _slogan,
            tags
        );
        Brand memory newBrand = Brand(_name, _symbol, brandContract);
        brands.push(newBrand);
        nonce[msg.sender] += 1;

        emit NewBrandEvent(_name, address(brandContract), msg.sender);
    }

    function listBrand() external view returns (Brand[] memory) {
        return brands;
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
    event NewBrandEvent(string name, address brandAddress, address owner);
}
