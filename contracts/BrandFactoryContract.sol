//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./BrandContract.sol";
import "./TagContract.sol";
import "./Util.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

// turn off revert strings
contract BrandFactoryContract is Ownable, Pausable {
    mapping(address => uint256) public nonce;
    TagContract public tagContract;

    struct Brand {
        string name;
        string symbol;
        address brandAddress;
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

        if (!Util.checkValidSignature(_signature)) {
            revert InvalidSignature();
        }

        if (_nonce != nonce[msg.sender]) {
            revert InvalidNonce();
        }

        TagContract.Tag[] memory tags = new TagContract.Tag[](tagIds.length);
        for (uint256 i = 0; i < tagIds.length; i++) {
            uint256 tagId = tagIds[i];
            TagContract.Tag memory tag = tagContract.getTag(tagId);
            tags[i] = tag;
        }

        BrandContract brandContract = new BrandContract(
            _name,
            _symbol,
            _logo,
            _slogan,
            tags
        );
        Brand memory newBrand = Brand(_name, _symbol, address(brandContract));
        brands.push(newBrand);
        nonce[msg.sender] += 1;

        emit NewBrandEvent(_name, address(brandContract), msg.sender);
    }

    function listBrand() external view returns (Brand[] memory) {
        return brands;
    }



    // errors
    error InvalidSignature();
    error InvalidTag();
    error InvalidNonce();
    error ContractAlreadyInitialized();

    // events
    event NewBrandEvent(string name, address brandAddress, address owner);
}


