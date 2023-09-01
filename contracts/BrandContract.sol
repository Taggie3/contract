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
import "./interfaces/IIPContract.sol";
import "./TagContract.sol";
import "./interfaces/IPaySplitter.sol";
import "./interfaces/IBrandUtil.sol";

// turn off revert strings
//TODO 压缩字节数
contract BrandContract is
ERC721Upgradeable,
ERC721EnumerableUpgradeable,
PausableUpgradeable,
OwnableUpgradeable,
ERC721BurnableUpgradeable,
ERC721RoyaltyUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    address public brandSetAddress;

    string public logo;
    string public slogan;
    TagContract.Tag[] public tags;

    IP[] public ips;

    mapping(uint256 => string) public tokenIdToUri;
    mapping(uint256 => IP) public tokenIdToIP;

    string public contractURI;

    IBrandUtil public brandUtil;
    uint256 public brandSetId;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        string memory _slogan,
        address _brandSetAddress,
        TagContract.Tag[] memory _tags,
        string memory _contractURI,
        IBrandUtil _brandUtil
    ) public initializer {
        __ERC721_init(_name, _symbol);
        require(_tags.length > 0, "tags length must > 0");
        for (uint256 i = 0; i < _tags.length; i++) {
            tags.push(_tags[i]);
        }
        // tags = _tags;
        logo = _logo;
        slogan = _slogan;
        brandSetAddress = _brandSetAddress;
        contractURI = _contractURI;
        brandUtil = _brandUtil;
        _transferOwnership(_brandSetAddress);

        // 配置默认版权分账
        address[] memory payees = new address[](2);
        uint256[] memory shares = new uint256[](2);
        payees[0] = brandUtil.getBrand3Admin();
        shares[0] = 1000;
        payees[1] = brandUtil.getBrand3Admin();
        shares[1] = 100;

        IPaySplitter paySplitter = brandUtil.buildSplitter(
            payees,
            shares,
            address(this)
        );
        address splitterAddress = address(paySplitter);

        _setDefaultRoyalty(splitterAddress, 1100);
    }

    // mint数量不限制，只能由owner进行mint，在mint指定splitter地址为版税受益人
    function mint(string memory ipUri, IIPContract _ipContract)
    public
    whenNotPaused
    {
        // 检查ip合约
        require(
            address(this) == _ipContract.brandContract(),
            "brandContractAddress error"
        );
        // 检查授权
        bool isValid = brandUtil.checkTokenBoundAccount(msg.sender, brandSetAddress, brandSetId);
        //        魔法值不能为0
        require(isValid, "invalid signer");


        string memory ipName = _ipContract.name();
        string memory ipSymbol = _ipContract.symbol();
        address ipOwner = _ipContract.owner();
        // 检查IP是否已存在
        for (uint256 i = 0; i < ips.length; i++) {
            IP memory ip = ips[i];
            require(
                address(ip.ipContract) != address(_ipContract),
                "IP address existed"
            );
            require(
                keccak256(bytes(ip.name)) != keccak256(bytes(ipName)),
                "IP name existed"
            );
        }

        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // 抛出新建IP事件
//        emit NewIPEvent(
//            tokenId,
//            ipName,
//            address(_ipContract),
//            address(this),
//            ipOwner
//        );

        // 新建IP
        IP memory newIP = IP(ipName, ipSymbol, _ipContract);
        ips.push(newIP);
        tokenIdToIP[tokenId] = newIP;
        tokenIdToUri[tokenId] = ipUri;
        _safeMint(ipOwner, tokenId);

        address ipAccount = brandUtil.createTokenBoundAccount(address(this), tokenId);

        //   nft交易版税5%给owner，5%给creator，1%给平台.通过splitter处理
        address[] memory payees = new address[](3);
        uint256[] memory shares = new uint256[](3);
        payees[0] = owner();
        shares[0] = 500;
        payees[1] = ipAccount;
        shares[1] = 500;
        payees[2] = brandUtil.getBrand3Admin();
        shares[2] = 100;

        IPaySplitter paySplitter = brandUtil.buildSplitter(
            payees,
            shares,
            address(this)
        );
        address splitterAddress = address(paySplitter);
        _setTokenRoyalty(tokenId, splitterAddress, 1100);
        _ipContract.updateBrandId(tokenId);
        _ipContract.transferOwnership(ipAccount);
    }

    // events
//    event NewIPEvent(
//        uint256 tokenId,
//        string ipName,
//        address ipAddress,
//        address brandAddress,
//        address ipOwner
//    );

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
    }

    function listTags() public view returns (TagContract.Tag[] memory) {
        return tags;
    }

    function listIPs() public view returns (IP[] memory) {
        return ips;
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
            //        调整所有的brand的版税
            address splitterAddress;
            (splitterAddress,) = super.royaltyInfo(i, 0);
            IPaySplitter splitter = IPaySplitter(splitterAddress);
            splitter.deletePayee(owner());
            splitter.addPayee(newOwner, 500);
            //        通知所有的ip brand的owner改变了
            IP memory ip = ips[i];
            ip.ipContract.updateBrandOwner(newOwner);
        }
        _transferOwnership(newOwner);
    }

    /**
     * 从该合约中提取所有的eth到owner
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent,) = _owner.call{value: amount}("");
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

//    modifier onlyBrandSet() {
//        _checkBrandSet();
//        _;
//    }
//
//    function _checkBrandSet() internal view virtual {
//        require(
//            brandSetAddress == msg.sender,
//            "Ownable: caller is not the brandSet"
//        );
//    }

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

    function updateBrandSetId(uint256 _brandSetId) public onlyOwner initializer {
        brandSetId = _brandSetId;
    }
}

    struct IP {
        string name;
        string symbol;
        IIPContract ipContract;
    }
