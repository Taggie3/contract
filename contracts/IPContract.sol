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
import "./PaySplitter.sol";

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
    address public constant brand3Admin =
        address(0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106);
    string public logo;
    IBrandContract public brandContract;

    mapping(uint256 => string) tokenIdToUri;

    string public contractURI;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _logo,
        IBrandContract _brandContract,
        address _creatorAddress,
        string memory _contractURI
    ) public initializer {
        __ERC721_init(_name, _symbol);
        logo = _logo;
        brandContract = _brandContract;
        contractURI = _contractURI;

        _transferOwnership(_creatorAddress);
        // 配置默认版税
        // 配置默认版权分账
        address[] memory payees = new address[](3);
        uint256[] memory shares = new uint256[](3);
        payees[0] = brandContract.owner();
        shares[0] = 500;
        payees[1] = owner();
        shares[1] = 1000;
        payees[2] = brand3Admin;
        shares[2] = 100;

        PaySplitter paySplitter = new PaySplitter(payees, shares);
        address splitterAddress = address(paySplitter);

        _setDefaultRoyalty(splitterAddress, 1600);
    }

    function mint(
        address creator,
        string memory MemeUri,
        uint256 memeId
    ) public whenNotPaused onlyOwner {
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        emit NewMemeEvent(
            tokenId,
            memeId,
            address(this),
            address(brandContract),
            creator
        );

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
        payees[3] = brand3Admin;
        shares[3] = 100;

        PaySplitter paySplitter = new PaySplitter(payees, shares);
        address splitterAddress = address(paySplitter);
        _setTokenRoyalty(tokenId, splitterAddress, 1600);
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
        onlyBrand
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            //        调整所有的meme的版税
            address splitterAddress;
            (splitterAddress, ) = super.royaltyInfo(i, 0);
            PaySplitter splitter = PaySplitter(payable(address(uint160(splitterAddress))));
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
            (splitterAddress, ) = super.royaltyInfo(i, 0);
            PaySplitter splitter = PaySplitter(payable(address(uint160(splitterAddress))));
            splitter.deletePayee(brandContract.owner());
            splitter.addPayee(newBrandOwner, 500);
        }
    }
}
