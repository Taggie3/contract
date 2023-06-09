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

contract IPContract is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721Burnable,
    ERC721Royalty
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public logo;
    address public brandAddress;

    mapping(uint256 => string) tokenIdToUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        address _brandAddress,
        address _creatorAddress
    ) payable ERC721(_name, _symbol) {
        logo = _logo;
        brandAddress = _brandAddress;
        _transferOwnership(_creatorAddress);
        // 配置默认版税
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
        address splitterAddress = address(paymentSplitter);

        _setDefaultRoyalty(splitterAddress, 250);
    }

    function mint(address creator, string memory MemeUri)
        public
        payable
        whenNotPaused
        onlyOwner
    {
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(creator, tokenId);
        tokenIdToUri[tokenId] = MemeUri;

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        if (super.owner() != creator) {
            address[] memory payees = new address[](3);
            payees[0] = tx.origin;
            payees[1] = creator;
            payees[2] = address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
            uint256[] memory shares = new uint256[](3);
            shares[0] = 100;
            shares[1] = 100;
            shares[2] = 50;
            PaymentSplitter paymentSplitter = new PaymentSplitter{
                value: msg.value
            }(payees, shares);
            address splitterAddress = address(paymentSplitter);
            _setTokenRoyalty(tokenId, splitterAddress, 250);
        }
    }

    function updateLogo(string memory _logo) public onlyOwner whenNotPaused {
        logo = _logo;
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
