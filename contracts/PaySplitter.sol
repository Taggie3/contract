// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPaySplitter.sol";

contract PaySplitter is Context, Ownable, IPaySplitter {
    event PayeeAdded(address account, uint256 shares);
    event PayeeDeleted(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    mapping(address => uint256) private addressToBalance;

    /**
     * @dev Creates an instance of `PaySplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_, address owner) {
        require(
            payees.length == shares_.length,
            "PaySplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaySplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            addPayee(payees[i], shares_[i]);
        }

        uint256 totalReceived = address(this).balance;
        if (totalReceived > 0) {
            release();
        }

        _transferOwnership(owner);

    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
        release();
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
    public
    view
    returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance;
        return _pendingPayment(account, totalReceived);
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account)
    public
    view
    returns (uint256)
    {
        uint256 totalReceived = token.balanceOf(address(this));
        return _pendingPayment(account, totalReceived);
    }

    /**
     * 将所有的token按照当前的分账比例直接进行转账
     */
    function release() public onlyOwner {
        require(_payees.length > 0, "PaySplitter: no payees");
        mapping(address => uint256) storage temp = addressToBalance;
        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payment = releasable(_payees[i]);
            require(
                payment != 0,
                "PaySplitter: account is not due payment"
            );
            temp[_payees[i]] = payment;
        }

        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payment = temp[_payees[i]];
            _totalReleased += payment;
            unchecked {
                _released[_payees[i]] += payment;
            }
            address payable toPayee = payable(address(uint160(_payees[i])));
            Address.sendValue(toPayee, payment);
            emit PaymentReleased(_payees[i], payment);
        }
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token) public onlyOwner {
        require(_payees.length > 0, "PaySplitter: no payees");
        mapping(address => uint256) storage temp = addressToBalance;

        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payment = releasable(token, _payees[i]);
            require(
                payment != 0,
                "PaySplitter: account is not due payment"
            );
            temp[_payees[i]] = payment;
        }

        for (uint256 i = 0; i < _payees.length; i++) {
            uint256 payment = temp[_payees[i]];
            _erc20TotalReleased[token] += payment;
            unchecked {
                _erc20Released[token][_payees[i]] += payment;
            }
            SafeERC20.safeTransfer(token, _payees[i], payment);
            emit ERC20PaymentReleased(token, _payees[i], payment);
        }
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(address account, uint256 totalReceived)
    private
    view
    returns (uint256)
    {
        return (totalReceived * _shares[account]) / _totalShares;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function addPayee(address account, uint256 shares_) public onlyOwner {
        require(
            account != address(0),
            "PaySplitter: account is the zero address"
        );
        require(shares_ > 0, "PaySplitter: shares are 0");
        //        如果已有账户，则直接增加份额
        for (uint256 i = 0; i < _payees.length; i++) {
            if (_payees[i] == account) {
                _shares[account] += shares_;
                return;
            }
        }


        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    //   deletePayee
    function deletePayee(address account) public onlyOwner {
        require(
            account != address(0),
            "PaySplitter: account is the zero address"
        );
        require(_shares[account] > 0, "PaySplitter: account has no shares");

        uint256 shares_ = _shares[account];
        _totalShares = _totalShares - shares_;
        delete _shares[account];
        removePayeeByAddress(account);
        emit PayeeDeleted(account, shares_);
    }

    function removePayeeByIndex(uint256 index) private {
        if (index < _payees.length) {
            _payees[index] = _payees[_payees.length - 1];
            _payees.pop();
        }
    }

    function removePayeeByAddress(address account) private {
        for (uint256 i = 0; i < _payees.length; i++) {
            if (_payees[i] == account) {
                removePayeeByIndex(i);
                break;
            }
        }
    }
}
