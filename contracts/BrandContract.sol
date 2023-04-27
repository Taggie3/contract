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
import "./TagContract.sol";
import "./IPContract.sol";

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

    //  slogan的logo图片地址
    string public logo;
    string public slogan;
    //  slogan对应的tag数据
    TagContract.Tag[] public tags;

    struct IP {
        string name;
        string symbol;
        IPContract ipContract;
    }

    IP[] public IPs;

    //  新增slogan收钱，无法在constructor中校验收钱，只能通过平台校验
    //  第1个slogan免费，第2个slogan收0.1ETH，第3个0.5ETH，第4个2.5ETH以此类推
    //  白名单校验只能通过前后端处理，构造方法中没办法处理预售期结束的逻辑
    constructor(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        string memory _logo,
        string memory _slogan,
        TagContract.Tag[] memory _tags
    ) payable ERC721(_name, _symbol) {
        for (uint256 i = 0; i < _tags.length; i++) {
            tags.push(_tags[i]);
        }
        _baseTokenURI = baseURI;
        logo = _logo;
        slogan = _slogan;

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
        _transferOwnership(tx.origin);
    }

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
    }

    function getTags() public view returns (TagContract.Tag[] memory) {
        return tags;
    }

    // mint数量不限制，只能由owner进行mint，在mint指定splitter地址为版税受益人
    function mint(address creator, address splitter)
        public
        whenNotPaused
        onlyOwner
    {
        //        TODO 验证签名
        require(creator != address(0), "creator is not a valid address");
        require(splitter != address(0), "splitter is not a valid address");
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(creator, tokenId);

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        address[] memory payees = new address[](3);
        payees[0] = tx.origin;
        payees[1] = creator;
        payees[2] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
        uint256[] memory shares = new uint256[](3);
        shares[0] = 100;
        shares[1] = 100;
        shares[2] = 50;
        PaymentSplitter paymentSplitter = new PaymentSplitter(payees, shares);
        _setTokenRoyalty(tokenId, address(paymentSplitter), 250);

        // TODO 抛出新建IP异常
        // emit NewPostEvent(postId, address(this), tokenId, creator, splitter);
    }

    //   slogan交易2.5%给到平台，通过交易平台处理

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

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // events
    event NewPostEvent(
        uint256 postId,
        address brandAddress,
        uint256 tokenId,
        address creator,
        address splitter
    );
}
