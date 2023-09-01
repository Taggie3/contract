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
import "./interfaces/IBrandContract.sol";
import "./interfaces/IPaySplitter.sol";
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
    IBrandContract public brandContract;

    mapping(uint256 => string) public tokenIdToUri;

    string public contractURI;
    IBrandUtil public brandUtil;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        IBrandContract _brandContract,
        string memory _contractURI,
        IBrandUtil _brandUtil
    ) public initializer {
        __ERC721_init(_name, _symbol);
        logo = _logo;
        brandContract = _brandContract;
        contractURI = _contractURI;
        brandUtil = _brandUtil;

        // _transferOwnership(address(_brandContract));
        // TODO 调试完改回来
        _transferOwnership(tx.origin);
        // 配置默认版税
        address[] memory payees = new address[](3);
        uint256[] memory shares = new uint256[](3);
        payees[0] = brandContract.owner();
        shares[0] = 500;
        payees[1] = brandUtil.getBrand3Admin();
        shares[1] = 1000;
        payees[2] = brandUtil.getBrand3Admin();
        shares[2] = 100;

        IPaySplitter paySplitter = brandUtil.buildSplitter(
            payees,
            shares,
            address(this)
        );
        address splitterAddress = address(paySplitter);

        _setDefaultRoyalty(splitterAddress, 1600);
    }

    function mint(
        address creator,
        string memory MemeUri
    ) public whenNotPaused onlyOwner {
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

//        emit NewMemeEvent(
//            tokenId,
//            address(this),
//            address(brandContract),
//            creator
//        );

        tokenIdToUri[tokenId] = MemeUri;
        _safeMint(creator, tokenId);

        address[] memory payees = new address[](4);
        uint256[] memory shares = new uint256[](4);
        payees[0] = brandContract.owner();
        shares[0] = 500;
        payees[1] = owner();
        shares[1] = 500;
        payees[2] = creator;
        shares[2] = 500;
        payees[3] = brandUtil.getBrand3Admin();
        shares[3] = 100;

        IPaySplitter paySplitter = brandUtil.buildSplitter(
            payees,
            shares,
            address(this)
        );
        address splitterAddress = address(paySplitter);
        _setTokenRoyalty(tokenId, splitterAddress, 1600);
    }

    // events
//    event NewMemeEvent(
//        uint256 tokenId,
//        address ipAddress,
//        address brandAddress,
//        address memeOwner
//    );

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
    }

    function updateBrandContract(IBrandContract _brandContract)
    public
    onlyOwner
    whenNotPaused
    {
        brandContract = _brandContract;
    }

    function transferOwnership(address newOwner)
    public
    virtual
    override
    onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            //        调整所有的meme的版税
            address splitterAddress;
            (splitterAddress,) = super.royaltyInfo(i, 0);
            IPaySplitter splitter = IPaySplitter(splitterAddress);
            splitter.deletePayee(owner());
            splitter.addPayee(newOwner, 500);
        }

        _transferOwnership(newOwner);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721RoyaltyUpgradeable
    )
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

    modifier onlyBrand() {
        _checkBrand();
        _;
    }

    function _checkBrand() internal view virtual {
        require(
            address(brandContract) == msg.sender,
            "Ownable: caller is not the brandContract"
        );
    }

    /**
     * brand的owner修改，调整版税
     */
    function updateBrandOwner(address newBrandOwner) public onlyBrand {
        require(
            newBrandOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            //        调整所有的meme的版税
            address splitterAddress;
            (splitterAddress,) = super.royaltyInfo(i, 0);
            IPaySplitter splitter = IPaySplitter(splitterAddress);
            splitter.deletePayee(brandContract.owner());
            splitter.addPayee(newBrandOwner, 500);
        }
    }

    function updateContractUri(string memory _contractUri)
    public
    onlyOwner
    whenNotPaused
    {
        contractURI = _contractUri;
    }

    function updateTokenUri(string memory _tokenUri, uint256 tokenId)
    public
    onlyOwner
    whenNotPaused
    {
        tokenIdToUri[tokenId] = _tokenUri;
    }
}
