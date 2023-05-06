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
    TagContract public tagContract;

    struct Brand {
        string name;
        string symbol;
        address brandAddress;
    }

    Brand[] public brands;

    constructor(address tagContractAddress) {
        tagContract = TagContract(tagContractAddress);
    }

    function changeTagContract(address tagContractAddress) public onlyOwner whenNotPaused {
        tagContract = TagContract(tagContractAddress);
    }

    function createNewBrand(
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

        require(Util.checkValidSignature(_signature), "InvalidSignature");

        TagContract.Tag[] memory tags = Util.tagIdsToTags(tagIds, tagContract);

        BrandContract brandContract = new BrandContract(
            _name,
            _symbol,
            _logo,
            _slogan,
            tags
        );
        address brandAddress = address(brandContract);

        Brand memory newBrand = Brand(_name, _symbol, brandAddress);
        brands.push(newBrand);

        emit NewBrandEvent(_name, brandAddress, msg.sender);
    }

    function listBrand() external view returns (Brand[] memory) {
        return brands;
    }

    // errors
    error InvalidSignature();
    error InvalidNonce();

    // events
    event NewBrandEvent(string brandName, address brandAddress, address owner);
}
