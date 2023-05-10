//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./TagContract.sol";
import "./interfaces/IBrandContract.sol";
import "./interfaces/IBrandUtil.sol";

// turn off revert strings
contract BrandSetContract is
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
PausableUpgradeable,
OwnableUpgradeable,
ERC721BurnableUpgradeable,
ERC721RoyaltyUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    TagContract public tagContract;

    Brand[] public brands;

    mapping(uint256 => string) tokenIdToUri;
    mapping(uint256 => Brand) tokenIdToBrand;

    string public contractURI;

    IBrandUtil public brandUtil;

    function initialize(
        TagContract _tagContract,
        string memory _contractURI,
        IBrandUtil _brandUtil
    ) initializer public {
        __ERC721_init("Brand", "BRAND");
        tagContract = _tagContract;
        contractURI = _contractURI;
        brandUtil = _brandUtil;
        _transferOwnership(tx.origin);

        PaymentSplitter paymentSplitter = brandUtil.getDefaultSplitter();
        address splitterAddress = address(paymentSplitter);

        _setDefaultRoyalty(splitterAddress, 250);
    }

    function changeTagContract(address tagContractAddress)
    public
    onlyOwner
    whenNotPaused
    {
        tagContract = TagContract(tagContractAddress);
    }

    function mint(
        string memory brandUri,
        bytes memory signature,
        IBrandContract _brandContract
    ) public whenNotPaused {
        IBrandContract brandContract = _brandContract;

        require(
            address(this) == brandContract.brandSetAddress(),
            "brandSetAddress error"
        );

        string memory brandName = brandContract.name();
        string memory brandSymbol = brandContract.symbol();

        require(
            brandUtil.checkValidSignature(signature, brandName, this.owner()),
            "InvalidSignature"
        );
        // 检查brand是否已存在
        for (uint256 i = 0; i < brands.length; i++) {
            Brand memory brand = brands[i];
            require(
                keccak256(bytes(brand.name)) != keccak256(bytes(brandName)),
                "brand name existed"
            );
        }
        //        检查tag是否合法
        TagContract.Tag[] memory tags = brandContract.tags();
        for (uint256 i = 0; i < tags.length; i++) {
            TagContract.Tag memory tag = tags[i];
            TagContract.Tag memory existTag = tagContract.getTag(tag.tokenId);
            require(
                keccak256(bytes(tag.value)) == keccak256(bytes(existTag.value)),
                "tag not exist"
            );
        }

        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);
        tokenIdToUri[tokenId] = brandUri;

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理

        PaymentSplitter paymentSplitter = brandUtil.getSplitter(
            this.owner(),
            brandContract.owner()
        );
        _setTokenRoyalty(tokenId, address(paymentSplitter), 250);

        Brand memory newBrand = Brand(brandName, brandSymbol, brandContract);
        brands.push(newBrand);
        tokenIdToBrand[tokenId] = newBrand;

        emit NewBrandEvent(tokenId, brandName, brandContract, msg.sender);
    }

    event NewBrandEvent(
        uint256 tokenId,
        string brandName,
        IBrandContract brandContract,
        address brandOwner
    );

    function listBrand() external view returns (Brand[] memory) {
        return brands;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable) {
        IBrandContract brandContract = tokenIdToBrand[firstTokenId]
        .brandContract;
        brandContract.transferOwnership(to);
    }

    /**
     * 从该合约中提取所有的eth到owner
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent,) = _owner.call{value : amount}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
    {
        return super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        return tokenIdToUri[tokenId];
    }
}

struct Brand {
    string name;
    string symbol;
    IBrandContract brandContract;
}
