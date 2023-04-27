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
import "./IPContract.sol";
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

    string public logo;
    string public slogan;
    TagContract.Tag[] public tags;

    struct IP {
        string name;
        string symbol;
        address ipAddress;
    }

    IP[] public IPs;

    mapping(uint256 => string) tokenIdToUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        string memory _slogan,
        TagContract.Tag[] memory _tags
    ) payable ERC721(_name, _symbol) {
        for (uint256 i = 0; i < _tags.length; i++) {
            tags.push(_tags[i]);
        }
        logo = _logo;
        slogan = _slogan;
        _transferOwnership(tx.origin);

        // 配置默认版权分账
        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        address[] memory payees = new address[](2);
        payees[0] = tx.origin;
        payees[1] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
        uint256[] memory shares = new uint256[](2);
        shares[0] = 200;
        shares[1] = 50;
        PaymentSplitter paymentSplitter = new PaymentSplitter{value: msg.value}(
            payees,
            shares
        );

        _setDefaultRoyalty(address(paymentSplitter), 250);
    }

    // mint数量不限制，只能由owner进行mint，在mint指定splitter地址为版税受益人
    function mint(
        address creator,
        string memory IPUri,
        string memory _IPName,
        string memory _IPSymbol,
        string memory _IPLogo
    ) public payable whenNotPaused onlyOwner {
        //        TODO 验证签名
        require(creator != address(0), "creator is not a valid address");
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(creator, tokenId);
        tokenIdToUri[tokenId] = IPUri;

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        if (super.owner() != creator) {
            address[] memory payees = new address[](3);
            payees[0] = super.owner();
            payees[1] = creator;
            payees[2] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
            uint256[] memory shares = new uint256[](3);
            shares[0] = 100;
            shares[1] = 100;
            shares[2] = 50;
            PaymentSplitter paymentSplitter = new PaymentSplitter{
                value: msg.value
            }(payees, shares);
            _setTokenRoyalty(tokenId, address(paymentSplitter), 250);
        }

        // 新建IP合约
        IPContract ipContract = new IPContract(
            _IPName,
            _IPSymbol,
            _IPLogo,
            address(this),
            creator
        );
        IP memory ip = IP(_IPName, _IPSymbol, address(ipContract));
        IPs.push(ip);

        // 抛出新建IP事件
        emit NewIPEvent(
            tokenId,
            _IPName,
            address(ipContract),
            address(this),
            creator
        );
    }

    //   slogan交易2.5%给到平台，通过交易平台处理

    // events
    event NewIPEvent(
        uint256 tokenId,
        string IPName,
        address IPAddress,
        address brandAddress,
        address IPOwner
    );

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
    }

    function getTags() public view returns (TagContract.Tag[] memory) {
        return tags;
    }

    /**
     * 从该合约中提取所有的eth到owner
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
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
