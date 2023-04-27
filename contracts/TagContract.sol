// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TagContract is Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Tag {
        uint256 tokenId;
        string types;
        //tag的内容
        string value;
    }

    Tag[] public tags;

    function mint(string memory _tagTypes, string memory _tagValue)
        public
        whenNotPaused
    {
        //校验tagString是否已经被mint过了
        for (uint256 i = 0; i < tags.length; i++) {
            Tag memory tag = tags[i];
            require(
                keccak256(bytes(tag.value)) != keccak256(bytes(_tagValue)),
                "tag value existed"
            );
        }
        //更新tokenId
        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        //新建tag
        Tag memory newTag = Tag(_tokenId, _tagTypes, _tagValue);
        tags.push(newTag);

        emit NewTagEvent(_tokenId, _tagTypes, _tagValue);
    }

    function listTag() public view returns (Tag[] memory) {
        return tags;
    }

    function getTag(uint256 tokenId) external view returns (Tag memory) {
        return tags[tokenId];
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

    event NewTagEvent(uint256 tokenId, string types, string value);
}
