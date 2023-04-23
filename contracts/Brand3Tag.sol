// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IBrand3Tag.sol";

contract Brand3Tag is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Tag {
        uint256 tokenId;
        //tag的内容
        string value;
    }

    //tokenId对应的tag
    mapping(uint256 => Tag) public tokenIdToTag;
    //tagValue对应的tag
    mapping(string => Tag) public tagValueToTag;
    //tagValue是否已存在
    mapping(string => bool) public tagValueToExist;
    //记录所有已被授权可以mint的地址
    mapping(address => bool) public addressToMint;

    constructor() ERC721("Brand3Tag", "B3T") {
        addressToMint[msg.sender] = true;
    }

    function mint(string memory tagValue)
        public
        whenNotPaused
    {
        //校验tagString是否已经被mint过了
        require(!tagValueToExist[tagValue], "this tag existed");
        //记录tagValue已存在
        tagValueToExist[tagValue] = true;
        //更新tokenId
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        //新建tag
        Tag memory tag = Tag(tokenId, tagValue);
        //将tokenId对应的tag保存
        tagValueToTag[tagValue] = tag;
        tokenIdToTag[tokenId] = tag;
        _safeMint(msg.sender, tokenId);
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
