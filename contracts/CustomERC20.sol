// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract CustomERC20 is Multicall, Ownable, ERC2771Context {
    // Libraries
    using SafeCast for *;

    // Config
    string public _name;
    string public _symbol;

    mapping(address => uint256) public _privateDistribution;
    uint256 public _totalPrivateDistribution;
    uint256 public _holderDistribution;
    uint256 public _transferDistribution;

    // State
    mapping(address => uint256) public _balances; // Standard ERC20 stuff
    mapping(address => uint256) public _balanceDebts;
    mapping(address => mapping(address => uint256)) public _allowances; // More standard ERC20 stuff
    uint256 public _totalSupply;

    uint256 public _holderDistributionAmount; // Amount to multiply final balances by

    uint256 public _privateDistributionAmount; // Amount to add to balances

    // MetaTX
    mapping(address => bool) internal _forwarders;

    // Modifiers
    modifier initialized() {
        require(owner() == address(0));
        _;
    }

    // Constructor
    constructor() ERC2771Context(address(0)) {}

    // Initialization Functions
    function setName(string memory newName) public onlyOwner {
        _name = newName;
    }

    function setSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }

    function setDistributionForAddress(address recipient, uint256 distribution)
        public
        onlyOwner
    {
        _totalPrivateDistribution += distribution;
        _totalPrivateDistribution -= _privateDistribution[recipient];

        _privateDistribution[recipient] = distribution;
    }

    function setDistributionForHolders(uint256 distribution) public onlyOwner {
        _holderDistribution = distribution;
    }

    function setAmountTransferred(uint256 distribution) public onlyOwner {
        _transferDistribution = distribution;
    }

    function setBalance(address recipient, uint256 amount) public onlyOwner {
        _totalSupply += amount;
        _totalSupply -= _balances[recipient];

        _balances[recipient] = amount;
    }

    function setForwarder(address forwarder, bool isForwarder) public onlyOwner {
        _forwarders[forwarder] = isForwarder;
    }

    // Custom Getters for Custom Initialization
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Helpers (these use "true tokens")
    function _getTrueDistributionAmount(uint256 amount, uint256 scale)
        internal
        pure
        returns (uint256)
    {
        return (amount * scale) / (10**18);
    }

    function _getTrueBalance(address holder)
        internal
        view
        initialized
        returns (uint256)
    {
        return
            _balances[holder] +
            _getTrueDistributionAmount(
                _privateDistributionAmount,
                _privateDistribution[holder]
            ) -
            _balanceDebts[holder];
    }

    function _distributeTruePrivate(uint256 amount) internal initialized {
        _privateDistributionAmount += amount;
        _totalSupply += amount;
    }

    function _distributeTrueHolders(uint256 amount) internal initialized {
        _holderDistributionAmount +=
            (_holderDistributionAmount + 10**18) *
            amount *
            _totalSupply -
            10**18;
        _totalSupply += amount;
    }

    function _simplifyTrueDebts(address toSimplify) internal initialized {
        if (_balances[toSimplify] > _balanceDebts[toSimplify]) {
            _balances[toSimplify] -= _balanceDebts[toSimplify];
            _balanceDebts[toSimplify] = 0;
        } else {
            _balanceDebts[toSimplify] -= _balances[toSimplify];
            _balances[toSimplify] = 0;
        }
    }

    function _subtractTrueBalance(address from, uint256 amount)
        internal
        initialized
    {
        require(
            _getTrueBalance(from) > amount,
            "User doesn't have enough balance"
        );

        _balanceDebts[from] += amount;
        _totalSupply -= amount;
        _simplifyTrueDebts(from);
    }

    function _addTrueBalance(address to, uint256 amount) internal initialized {
        _balances[to] += amount;
        _totalSupply += amount;
        _simplifyTrueDebts(to);
    }

    function _transferTrue(
        address from,
        address to,
        uint256 amount
    ) internal initialized {
        _subtractTrueBalance(from, amount);
        _addTrueBalance(
            to,
            _getTrueDistributionAmount(amount, _transferDistribution)
        );
        _distributeTruePrivate(
            _getTrueDistributionAmount(amount, _totalPrivateDistribution)
        );
        _distributeTrueHolders(
            _getTrueDistributionAmount(amount, _holderDistribution)
        );
    }

    // Helpers
    function _trueToVisible(uint256 amount)
        internal
        view
        initialized
        returns (uint256)
    {
        return _getTrueDistributionAmount(amount, _holderDistributionAmount);
    }

    function _visibleToTrue(uint256 amount)
        internal
        view
        initialized
        returns (uint256)
    {
        // Can't be simplified :(
        return (amount * (10**18)) / (_holderDistributionAmount + 10**18);
    }

    // Custom Getters for ERC20 Properties
    function totalSupply() public view returns (uint256) {
        return _trueToVisible(_totalSupply);
    }

    function balanceOf(address holder) public view returns (uint256 balance) {
        return _trueToVisible(_getTrueBalance(holder));
    }

    function allowance(address holder, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[holder][spender];
    }

    // Custom Methods for ERC20 Properties
    function transfer(address to, uint256 value)
        public
        initialized
        returns (bool success)
    {
        _transferTrue(_msgSender(), to, _visibleToTrue(value));
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public initialized returns (bool success) {
        require(
            _allowances[from][_msgSender()] >= value,
            "Not enough allowance"
        );

        _allowances[from][_msgSender()] -= value;
        _transferTrue(from, to, _visibleToTrue(value));
        return true;
    }

    function approve(address spender, uint256 value)
        public
        initialized
        returns (bool success)
    {
        _allowances[_msgSender()][spender] = value;
        return true;
    }

    // Overrides
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes memory)
    {
        return ERC2771Context._msgData();
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    // Meta TX custom forwarders
    function isTrustedForwarder(address forwarder) public view override returns (bool) {
        return _forwarders[forwarder];
    }
}
