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
        //tag的顺序
        uint16 sortLevel;
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

    modifier onlyMinter() {
        require(addressToMint[_msgSender()], "caller is not the minter");
        _;
    }

    constructor() ERC721("Brand3Tag", "B3T") {
        addressToMint[msg.sender] = true;
    }

    function mint(string memory tagValue, uint16 sortLevel)
    public
    onlyMinter
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
        Tag memory tag = Tag(tokenId, sortLevel, tagValue);
        //将tokenId对应的tag保存
        tagValueToTag[tagValue] = tag;
        tokenIdToTag[tokenId] = tag;
        _safeMint(msg.sender, tokenId);
    }

    function makeSlogan(uint256[] memory tokenIds, string[] memory linkStrs)
    public
    view
    whenNotPaused
    returns (string memory)
    {
        string memory result;
        uint256 linkStrsLength = linkStrs.length;
        uint16 nowSortLevel = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Tag memory tag = tokenIdToTag[tokenIds[i]];
            //如果当前排序等级比tag的排序等级小，说明tokenIds给的顺序不对
            require(
                tag.sortLevel >= nowSortLevel,
                "tag's sortLevel is smaller than nowArea.That means the TokenIds's sort is wrong or you give a wrong tokenId"
            );
            //tag排序等于当前排序，则添加tag内容到字符串中
            if (nowSortLevel == tag.sortLevel) {
                //如果是开头的字符串，则不添加空格，否则添加空格
                if (bytes(result).length > 0) {
                    result = string.concat(result, " ");
                }
                result = string.concat(result, tag.value);
            } else if (nowSortLevel < tag.sortLevel) {
                //tag排序大于当前排序，则添加连接字符串，然后再添加tag内容，然后更新当前排序等级
                if (linkStrsLength > nowSortLevel) {
                    if (bytes(result).length > 0) {
                        result = string.concat(result, " ");
                    }
                    result = string.concat(result, linkStrs[nowSortLevel]);
                }

                if (bytes(result).length > 0) {
                    result = string.concat(result, " ");
                }
                result = string.concat(result, tag.value);
                nowSortLevel = tag.sortLevel;
            }
        }
        //结束tag拼接后还要判断是否有结尾字符串
        if (linkStrsLength > nowSortLevel) {
            if (bytes(result).length > 0) {
                result = string.concat(result, " ");
            }
            result = string.concat(result, linkStrs[nowSortLevel]);
        }

        return result;
    }

    function addMintAddress(address addr) public onlyOwner whenNotPaused {
        addressToMint[addr] = true;
    }

    function delMintAddress(address addr) public onlyOwner whenNotPaused {
        addressToMint[addr] = false;
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
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
