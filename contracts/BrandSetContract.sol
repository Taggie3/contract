//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./TagContract.sol";
import "./interfaces/IBrandContract.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// turn off revert strings
contract BrandSetContract is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721Burnable,
    ERC721Royalty
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    TagContract public tagContract;

    struct Brand {
        string name;
        string symbol;
        address brandAddress;
    }

    Brand[] public brands;

    mapping(uint256 => string) tokenIdToUri;
    mapping(uint256 => Brand) tokenIdToBrand;

    constructor() payable ERC721("Brand", "BRAND") {
        _transferOwnership(tx.origin);

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

    function changeTagContract(address tagContractAddress)
        public
        onlyOwner
        whenNotPaused
    {
        tagContract = TagContract(tagContractAddress);
    }

    function mint(
        string memory brandUri,
        bytes memory signature,
        address brandContractAddress
    ) public payable whenNotPaused {
        IBrandContract brandContract = IBrandContract(brandContractAddress);

        require(
            address(this) == brandContract.brandSetAddress(),
            "brandSetAddress error"
        );

        string memory brandName = brandContract.name();
        string memory brandSymbol = brandContract.symbol();

        require(
            this.checkValidSignature(signature, brandName, this.owner()),
            "InvalidSignature"
        );
        address brandOwner = brandContract.owner();
        // 检查brand是否已存在
        for (uint256 i = 0; i < brands.length; i++) {
            Brand memory brand = brands[i];
            require(
                keccak256(bytes(brand.name)) != keccak256(bytes(brandName)),
                "brand name existed"
            );
        }
        //        检查tag是否合法
        TagContract.Tag[] memory tags = brandContract.tags();
        for (uint256 i = 0; i < tags.length; i++) {
            TagContract.Tag memory tag = tags[i];
            TagContract.Tag memory existTag = tagContract.getTag(tag.tokenId);
            require(
                keccak256(bytes(tag.value)) == keccak256(bytes(existTag.value)),
                "tag not exist"
            );
        }

        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);
        tokenIdToUri[tokenId] = brandUri;

        //   nft交易版税1%给owner，1%给creator，0.5%给平台.通过splitter处理
        if (super.owner() != brandOwner) {
            address[] memory payees = new address[](3);
            payees[0] = tx.origin;
            payees[1] = brandOwner;
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

        Brand memory newBrand = Brand(
            brandName,
            brandSymbol,
            brandContractAddress
        );
        brands.push(newBrand);
        tokenIdToBrand[tokenId] = newBrand;

        emit NewBrandEvent(
            tokenId,
            brandName,
            brandContractAddress,
            msg.sender
        );
    }

    event NewBrandEvent(
        uint256 tokenId,
        string brandName,
        address brandContractAddress,
        address brandOwner
    );

    function listBrand() external view returns (Brand[] memory) {
        return brands;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721) {
        address brandAddress = tokenIdToBrand[firstTokenId].brandAddress;
        IBrandContract brandContract = IBrandContract(brandAddress);
        brandContract.transferOwnership(to);
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

    function checkValidSignature(
        bytes memory signature,
        string memory message,
        address signer
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(message);
        return
            SignatureChecker.isValidSignatureNow(
                signer,
                messageHash,
                signature
            );
    }

    function getMessageHash(string memory message)
        public
        pure
        returns (bytes32)
    {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(message).length),
                bytes(message)
            )
        );

        return messageHash;
    }
}