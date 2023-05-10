// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import from the openzeppelin
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./interfaces/IBrandUtil.sol";

contract IPContract is
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
PausableUpgradeable,
OwnableUpgradeable,
ERC721BurnableUpgradeable,
ERC721RoyaltyUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    string public logo;
    address public brandAddress;

    mapping(uint256 => string) tokenIdToUri;

    string public contractURI;

    IBrandUtil public brandUtil;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        address _brandAddress,
        address _creatorAddress,
        string memory _contractURI,
        IBrandUtil _brandUtil
    ) initializer public {
        __ERC721_init(_name, _symbol);
        logo = _logo;
        brandAddress = _brandAddress;
        contractURI = _contractURI;
        brandUtil = _brandUtil;

        _transferOwnership(_creatorAddress);
        // 配置默认版税
        PaymentSplitter paymentSplitter = brandUtil.getDefaultSplitter();
        address splitterAddress = address(paymentSplitter);

        _setDefaultRoyalty(splitterAddress, 250);
    }

    function mint(address creator, string memory MemeUri, uint256 memeId)
    public
    whenNotPaused
    onlyOwner
    {
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(creator, tokenId);
        tokenIdToUri[tokenId] = MemeUri;

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理

        PaymentSplitter paymentSplitter = brandUtil.getSplitter(
            this.owner(),
            creator
        );
        address splitterAddress = address(paymentSplitter);
        _setTokenRoyalty(tokenId, splitterAddress, 250);


        emit NewMemeEvent(
            tokenId,
            memeId,
            address(this),
            brandAddress,
            creator
        );
    }

    // events
    event NewMemeEvent(
        uint256 tokenId,
        uint256 memeId,
        address ipAddress,
        address brandAddress,
        address memeOwner
    );

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
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
