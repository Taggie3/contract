//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./BrandContract.sol";
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
    address tagAddress;

    struct Brand {
        string name;
        string symbol;
        address brandAddress;
    }

    Brand[] public brands;
    mapping(string => bool) brandExist;

    constructor(address _tagAddress) {
        tagAddress = _tagAddress;
    }

    function changeTagContract(address _tagAddress) public onlyOwner {
        tagAddress = _tagAddress;
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
        require(!brandExist[_name], "brand existed");
        require(Util.checkValidSignature(_signature), "InvalidSignature");

        if (_nonce != nonce[msg.sender]) {
            revert InvalidNonce();
        }

        // TagContract.Tag[] memory tags = Util.tagIdsToTags(tagIds, tagContract);

        BrandContract brandContract = new BrandContract(
            _name,
            _symbol,
            _logo,
            _slogan,
            tagIds
        );
        address brandAddress = address(brandContract);

        Brand memory newBrand = Brand(_name, _symbol, brandAddress);
        brands.push(newBrand);
        nonce[msg.sender] += 1;

        brandExist[_name] = true;

        emit NewBrandEvent(_name, brandAddress, msg.sender);
    }

    function listBrand() external view returns (Brand[] memory) {
        return brands;
    }

    // errors
    error InvalidSignature();
    error InvalidNonce();

    // events
    event NewBrandEvent(string name, address brandAddress, address owner);
}
