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
import "./interfaces/IIPContract.sol";
import "./TagContract.sol";
import "./Util.sol";

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

    IP[] public ips;

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
        // tags = _tags;
        logo = _logo;
        slogan = _slogan;
        _transferOwnership(tx.origin);

        // 配置默认版权分账
        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        address splitterAddress = Util.getDefaultSplitter();

        _setDefaultRoyalty(splitterAddress, 250);
    }

    // mint数量不限制，只能由owner进行mint，在mint指定splitter地址为版税受益人
    function mint(
        string memory ipUri,
        // string memory _signature,
        address ipContractAddress
    ) public payable whenNotPaused onlyOwner {
        // require(Util.checkValidSignature(_signature), "InvalidSignature");
        // 检查ip合约
        IIPContract ipContract = IIPContract(ipContractAddress);
        require(
            address(this) == ipContract.brandAddress(),
            "brandAddress error"
        );

        string memory ipName = ipContract.name();
        string memory IPSymbol = ipContract.symbol();
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
            address splitterAddress = Util.getSplitter(tx.origin, ipOwner);
            _setTokenRoyalty(tokenId, splitterAddress, 250);
        }

        // 新建IP合约
        IP memory newIP = IP(ipName, IPSymbol, ipContractAddress);
        ips.push(newIP);

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
