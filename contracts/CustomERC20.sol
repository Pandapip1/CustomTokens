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
    string public tokenName;
    string public tokenSymbol;

    mapping(address => uint256) public privateDistribution;
    uint256 public totalPrivateDistribution;
    uint256 public holderDistribution;
    uint256 public transferDistribution;

    // State
    mapping(address => uint256) public balances; // Standard ERC20 stuff
    mapping(address => uint256) public balanceDebts;
    mapping(address => mapping(address => uint256)) public allowances; // More standard ERC20 stuff
    uint256 public trueTotalSupply;

    uint256 public holderDistributionAmount; // Amount to multiply final balances by

    uint256 public privateDistributionAmount; // Amount to add to balances

    // MetaTX
    mapping(address => bool) internal forwarders;

    // Modifiers
    modifier initialized() {
        require(owner() == address(0));
        _;
    }

    // Constructor
    constructor() ERC2771Context(address(0)) {
        holderDistributionAmount = 10 ** 18;
    }

    // Initialization Functions
    function setName(string memory _name) public onlyOwner {
        tokenName = _name;
    }

    function setSymbol(string memory _symbol) public onlyOwner {
        tokenSymbol = _symbol;
    }

    function setDistributionForAddress(address _recipient, uint256 _distribution)
        public
        onlyOwner
    {
        totalPrivateDistribution += _distribution;
        totalPrivateDistribution -= privateDistribution[_recipient];

        privateDistribution[_recipient] = _distribution;
    }

    function setDistributionForHolders(uint256 _distribution) public onlyOwner {
        holderDistribution = _distribution;
    }

    function setAmountTransferred(uint256 _distribution) public onlyOwner {
        transferDistribution = _distribution;
    }

    function setBalance(address _recipient, uint256 _amount) public onlyOwner {
        trueTotalSupply += _amount;
        trueTotalSupply -= balances[_recipient];

        balances[_recipient] = _amount;
    }

    function setForwarder(address _forwarder, bool _isForwarder) public onlyOwner {
        forwarders[_forwarder] = _isForwarder;
    }

    // Custom Getters for Custom Initialization
    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    // Custom Getters for ERC20 Properties
    function totalSupply() public view returns (uint256) {
        return _trueToVisible(trueTotalSupply);
    }

    function balanceOf(address _holder) public view returns (uint256 balance) {
        return _trueToVisible(_getTrueBalance(_holder));
    }

    function allowance(address _holder, address _spender)
        public
        view
        returns (uint256)
    {
        return allowances[_holder][_spender];
    }

    // Custom Methods for ERC20 Properties
    function transfer(address _to, uint256 _value)
        public
        initialized
        returns (bool)
    {
        _transferTrue(_msgSender(), _to, _visibleToTrue(_value));
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public initialized returns (bool) {
        require(
            allowances[_from][_msgSender()] >= _value,
            "Not enough allowance"
        );

        allowances[_from][_msgSender()] -= _value;
        _transferTrue(_from, _to, _visibleToTrue(_value));
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        initialized
        returns (bool)
    {
        allowances[_msgSender()][_spender] = _value;
        return true;
    }

    // Helpers (these use "true tokens")
    function _getTrueDistributionAmount(uint256 _amount, uint256 _scale)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _scale) / (10**18);
    }

    function _getTrueBalance(address _holder)
        internal
        view
        initialized
        returns (uint256)
    {
        return
            balances[_holder] +
            privateDistributionAmount * privateDistribution[_holder] / totalPrivateDistribution -
            balanceDebts[_holder];
    }

    function _distributeTruePrivate(uint256 _amount) internal initialized {
        privateDistributionAmount += _amount;
        trueTotalSupply += _amount;
    }

    function _distributeTrueHolders(uint256 _amount) internal initialized {
        holderDistributionAmount *= (_amount + trueTotalSupply) / trueTotalSupply;
        trueTotalSupply += _amount;
    }

    function _simplifyTrueDebts(address _toSimplify) internal initialized {
        if (balances[_toSimplify] > balanceDebts[_toSimplify]) {
            balances[_toSimplify] -= balanceDebts[_toSimplify];
            balanceDebts[_toSimplify] = 0;
        } else {
            balanceDebts[_toSimplify] -= balances[_toSimplify];
            balances[_toSimplify] = 0;
        }
    }

    function _subtractTrueBalance(address _from, uint256 _amount)
        internal
        initialized
    {
        require(
            _getTrueBalance(_from) >= _amount,
            "User doesn't have enough balance"
        );

        balanceDebts[_from] += _amount;
        trueTotalSupply -= _amount;
        _simplifyTrueDebts(_from);
    }

    function _addTrueBalance(address _to, uint256 _amount) internal initialized {
        balances[_to] += _amount;
        trueTotalSupply += _amount;
        _simplifyTrueDebts(_to);
    }

    function _transferTrue(
        address _from,
        address _to,
        uint256 _amount
    ) internal initialized {
        _subtractTrueBalance(_from, _amount);
        _addTrueBalance(
            _to,
            _getTrueDistributionAmount(_amount, transferDistribution)
        );
        _distributeTruePrivate(
            _getTrueDistributionAmount(_amount, totalPrivateDistribution)
        );
        _distributeTrueHolders(
            _getTrueDistributionAmount(_amount, holderDistribution)
        );
    }

    // Helpers
    function _trueToVisible(uint256 _amount)
        internal
        view
        initialized
        returns (uint256)
    {
        return (_amount * holderDistributionAmount) / (10**18);
    }

    function _visibleToTrue(uint256 _amount)
        internal
        view
        initialized
        returns (uint256)
    {
        return (_amount * (10**18)) / holderDistributionAmount;
    }

    // Overrides
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
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
        return forwarders[forwarder];
    }
}
