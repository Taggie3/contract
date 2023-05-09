// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import from the openzeppelin
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./interfaces/IIPContract.sol";
import "./TagContract.sol";

// turn off revert strings
contract BrandContract is
ERC721,
ERC721Enumerable,
Pausable,
Ownable,
ERC721Burnable,
ERC721Royalty
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string _baseTokenURI;
    address public brandSetAddress;

    string public logo;
    string public slogan;
    TagContract.Tag[] public tags;

    struct IP {
        string name;
        string symbol;
        address ipAddress;
    }

    IP[] public ips;

    mapping(uint256 => string) tokenIdToUri;
    mapping(uint256 => IP) tokenIdToIP;

    string public contractURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        string memory _slogan,
        address _brandSetAddress,
        TagContract.Tag[] memory _tags,
        string memory _contractURI
    ) payable ERC721(_name, _symbol) {
        require(_tags.length > 0, "tags length must > 0");
        for (uint256 i = 0; i < _tags.length; i++) {
            tags.push(_tags[i]);
        }
        // tags = _tags;
        logo = _logo;
        slogan = _slogan;
        brandSetAddress = _brandSetAddress;
        contractURI = _contractURI;
        _transferOwnership(tx.origin);

        // 配置默认版权分账
        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        address[] memory payees = new address[](2);
        payees[0] = tx.origin;
        payees[1] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
        uint256[] memory shares = new uint256[](2);
        shares[0] = 200;
        shares[1] = 50;
        PaymentSplitter paymentSplitter = new PaymentSplitter{value : msg.value}(
            payees,
            shares
        );
        address splitterAddress = address(paymentSplitter);

        _setDefaultRoyalty(splitterAddress, 250);
    }

    // mint数量不限制，只能由owner进行mint，在mint指定splitter地址为版税受益人
    function mint(
        string memory ipUri,
        address ipContractAddress
    ) public payable whenNotPaused onlyOwner {
        // 检查ip合约
        IIPContract ipContract = IIPContract(ipContractAddress);
        require(
            address(this) == ipContract.brandAddress(),
            "brandAddress error"
        );

        string memory ipName = ipContract.name();
        string memory ipSymbol = ipContract.symbol();
        address ipOwner = ipContract.owner();
        // 检查IP是否已存在
        for (uint256 i = 0; i < ips.length; i++) {
            IP memory ip = ips[i];
            require(ip.ipAddress != ipContractAddress, "IP address existed");
            require(
                keccak256(bytes(ip.name)) != keccak256(bytes(ipName)),
                "IP name existed"
            );
        }

        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(ipOwner, tokenId);
        tokenIdToUri[tokenId] = ipUri;

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        if (super.owner() != ipOwner) {
            address[] memory payees = new address[](3);
            payees[0] = tx.origin;
            payees[1] = ipOwner;
            payees[2] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
            uint256[] memory shares = new uint256[](3);
            shares[0] = 100;
            shares[1] = 100;
            shares[2] = 50;
            PaymentSplitter paymentSplitter = new PaymentSplitter{
            value : msg.value
            }(payees, shares);
            address splitterAddress = address(paymentSplitter);
            _setTokenRoyalty(tokenId, splitterAddress, 250);
        }

        // 新建IP
        IP memory newIP = IP(ipName, ipSymbol, ipContractAddress);
        ips.push(newIP);
        tokenIdToIP[tokenId] = newIP;

        // 抛出新建IP事件
        emit NewIPEvent(
            tokenId,
            ipName,
            ipContractAddress,
            address(this),
            ipOwner
        );
    }

    //   slogan交易2.5%给到平台，通过交易平台处理

    // events
    event NewIPEvent(
        uint256 tokenId,
        string ipName,
        address ipAddress,
        address brandAddress,
        address ipOwner
    );

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
    }

    function listTags() public view returns (TagContract.Tag[] memory) {
        return tags;
    }

    function listIPs() public view returns (IP[] memory) {
        return ips;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721) {
        address ipAddress = tokenIdToIP[firstTokenId].ipAddress;
        IIPContract ipContract = IIPContract(ipAddress);
        ipContract.transferOwnership(to);
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
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721, ERC721Royalty)
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
