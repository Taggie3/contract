//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./interfaces/IBrandContract.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC6551Registry.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Test {
    function test(address brandAddress) public {
        IBrandContract brandContract = IBrandContract(brandAddress);
        brandContract.transferOwnership(tx.origin);
    }

    function test2(
        address _nftAddress,
        address _signer,
        uint256 _salt,
        bytes calldata _context
    ) public returns (bytes4 magicValue) {
        emit log(1);
        address ipAccount = test3(_nftAddress, _salt);
        emit log(2);

        address payable ipAccount2 = payable(ipAccount);
        emit log(3);
        IERC6551Account erc6551Account = IERC6551Account(ipAccount2);
        emit log(4);
        // return bytes4(keccak256("1"));
        return erc6551Account.isValidSigner(_signer, _context);
    }

    event log(uint256 a);

    function test3(address _nftAddress, uint256 _salt)
        public
        view
        returns (address)
    {
        address accountImpl = 0x2D25602551487C3f3354dD80D76D54383A243358;
        address ipAccount = IERC6551Registry(
            0x02101dfB77FDE026414827Fdc604ddAF224F0921
        ).account(accountImpl, uint256(80001), _nftAddress, 0, _salt);
        return ipAccount;
    }

    function test4() public view returns (uint256) {
        return block.chainid;
    }

    function test5(address payable ipAccount, bytes calldata _context)
        public
        view
        returns (bytes4 magicValue)
    {
        IERC6551Account erc = IERC6551Account(ipAccount);
        return
            erc.isValidSigner(
                0xC8D64fdCA7DE05204b19cA62151fC4cd50Bcd106,
                _context
            );
    }

    function owner() public view returns (address) {
        return
            IERC721(0x1ed571C2643FDfBDAb6e395eD5F59B78438Ad10d).ownerOf(
                uint256(1)
            );
    }

    function checkOwner(address account) public view returns (bool) {
        return account == owner();
    }

    fallback() external payable {
        // 处理发送的以太币
        // 此处可以添加您的逻辑
    }

    receive() external payable {}
}
