// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/v3.0/ABDKMathQuad.sol";

contract CustomizableERC20 is Multicall, Ownable {
    // Libraries
    using SafeCast for *;
    using ABDKMathQuad for *;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
    
    // Config
    string private _name = "Uninitialized Token";
    string private _symbol = "UNINIT";
    
    mapping(address => uint256) private _privateDistribution;
    uint256 private _totalPrivateDistribution = 0;
    uint256 private _holderDistribution = 0;
    uint256 private _transferDistribution = 0;
    
    // State
    mapping(address => uint256) private _balances; // Standard ERC20 stuff
    mapping(address => uint256) private _balanceDebts;
    mapping(address => mapping(address => uint256)) private _allowances; // More standard ERC20 stuff
    uint256 private _totalSupply = 0;
    
    uint256 private _holderDistributionAmount = 10**18; // Amount to multiply final balances by
    
    uint256 private _privateDistributionAmount = 0; // Amount to add to balances
    
    // Constructor
    constructor() {}
    
    // Initialization Functions
    function setName(string memory newName) public onlyOwner {
        _name = newName;
    }
    
    function setSymbol(string memory newSymbol) public onlyOwner {
        _symbol = newSymbol;
    }
    
    function setDistributionForAddress(address recipient, uint256 distribution) public onlyOwner {
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
    
    function setBalance(address recipient, int256 amount) public onlyOwner {
        _totalSupply += amount;
        _totalSupply -= _balances[recipient];
        
        _balances[recipient] = amount;
    }
    
    // Custom Getters for Custom Initialization
    function name() public view returns (string memory) {
        if (owner() != address(0)) {
            return "Uninitialized Token";
        }
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        if (owner() != address(0)) {
            return "UNINIT";
        }
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return 18;
    }

    // Helpers (these use "true tokens")
    function _getTrueBalance(address toGet) internal view returns (uint256) {
        return _balances[toGet] + _privateDistributionAmount.fromUInt().mul(_privateDistribution[toGet].fromUInt()).div((10 ** 18).fromUInt()).toUInt() - _balanceDebts[toGet];
    }

    function _distributeTrueAmount(uint256 amount) internal {
        _holderDistributionAmount = _holderDistributionAmount.fromUInt().div(_totalSupply.fromUInt()).mul(amount.fromUInt()).toUInt();
        _privateDistributionAmount += amount;
        _totalSupply += amount;
    }

    function _simplifyTrueDebts(address toSimplify) internal {
        if (_balances[toSimplify] > _balanceDebts[toSimplify]) {
            _balances[toSimplify] -= balanceDebts[toSimplify];
            _balanceDebts[toSimplify] = 0;
        } else {
            _balanceDebts[toSimplify] -= _balances[toSimplify];
            _balances[toSimplify] = 0;
        }
    }

    function _subtractTrueBalance(address from, uint256 amount) internal {
        require(_getTrueBalance(from) > amount, "User doesn't have enough balance");
        
        _balanceDebts[from] += amount;
        _totalSupply -= amount;
        _simplifyTrueDebts(from);
    }

    function _addTrueBalance(address to, uint256 amount) internal {
        _balances[to] += amount;
        _totalSupply += amount;
        _simplifyTrueDebts(to);
    }

    function _transferTrue(address from, address to, uint256 amount) internal {
        _subtractTrueBalance(from, amount);
        _addTrueBalance(to, amount.fromUInt().mul(_transferDistribution.fromUInt()).div((10 ** 18).fromUInt()).toUInt());
        _distributeAmount(amount.fromUInt().mul((_totalPrivateDistribution + _holderDistribution).fromUInt()).div((10 ** 18).fromUInt()).toUInt());
    }

    // Helpers
    function _trueToVisible(uint256 amount) internal view returns (uint256) {
        return amount.fromUInt().mul(_holderDistributionAmount).div((10 ** 18).fromUInt()).toUInt();
    }
    
    function _visibleToTrue(uint256 amount) internal view returns (uint256) {
        return amount.fromUInt().mul((10 ** 18).fromUInt()).div(_holderDistributionAmount).toUInt();
    }

    // Custom Getters for ERC20 Properties
    function totalSupply() public view returns (uint256) {
        return _trueToVisible(_totalSupply);
    }
    
    function balanceOf(address holder) public view returns (uint256 balance) {
        return _trueToVisible(_getTrueBalance(holder));
    }
    
    function allowance(address holder, address spender) public view returns (uint256 remaining) {
        return _allowances[holder][spender];
    }
    
    // Custom Methods for ERC20 Properties
    function transfer(address to, uint256 value) public returns (bool success) {
        require(owner() == address(0), "Token not initialized");

        _transferTrue(msg.sender, to, _visibleToTrue(value));
        emit Transfer(from, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(owner() == address(0), "Token not initialized");
        require(_allowances[msg.sender][from] >= value, "Not enough allowance");

        _allowances[msg.sender][from] -= value;
        _transferTrue(from, to, _visibleToTrue(value));
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        require(owner() == address(0), "Token not initialized");

        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
