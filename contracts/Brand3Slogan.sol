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
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

contract Brand3Slogan is
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
    string public logoUrl;
    //  slogan对应的tag数据
    uint256[] public tagIds;

    //  新增slogan收钱，无法在constructor中校验收钱，只能通过平台校验
    //  第1个slogan免费，第2个slogan收0.1ETH，第3个0.5ETH，第4个2.5ETH以此类推
    //  白名单校验只能通过前后端处理，构造方法中没办法处理预售期结束的逻辑
    constructor(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        string memory _logoUrl,
        uint256[] memory _tagIds
    ) ERC721(_name, _symbol) {
        //记录与slogan相关的tag的数据
        tagIds = _tagIds;
        _baseTokenURI = baseURI;
        _setDefaultRoyalty(tx.origin, 250);
        logoUrl = _logoUrl;
        _transferOwnership(tx.origin);
    }

    function updateLogo(string memory _logoUrl) public onlyOwner whenNotPaused {
        logoUrl = _logoUrl;
    }

    // mint数量不限制，只能由owner进行mint，在mint指定splitter地址为版税受益人
    function mint(address creator, address splitter)
        public
        onlyOwner
        whenNotPaused
    {
        require(creator != address(0), "creator is not a valid address");
        require(splitter != address(0), "splitter is not a valid address");
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(creator, tokenId);
        _setTokenRoyalty(tokenId, splitter, 250);
        emit Minted(address(this), tokenId, creator, splitter);
    }

    //   slogan交易2.5%给到平台，通过交易平台处理

    //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理

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
    event Minted(
        address sloganAddress,
        uint256 tokenId,
        address creator,
        address splitter
    );

    function getTagIds() public view returns (uint256[] memory) {
        return tagIds;
    }
}
