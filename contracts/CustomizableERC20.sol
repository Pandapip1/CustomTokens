// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/v3.0/ABDKMathQuad.sol";

contract CustomizableERC777 is Multicall, Ownable, SafeCast, ABDKMathQuad {
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value)
    
    // Config
    string private _name = "Uninitialized Token";
    string private _symbol = "UNINIT";
    
    mapping(address => int256) private _privateRedistribution;
    int256 private _holderRedistribution = 0;
    int256 private _transferDistribution = 0;
    
    // Derived Config
    int256 private _totalRedistribution = 0;
    
    int256 private _totalPrivateRedistribution = 0;
    
    // State
    mapping(address => int256) private _balances; // Standard ERC20 stuff
    mapping(address => mapping(address => int256)) private _allowances; // More standard ERC20 stuff
    int256 private _totalSupply = 0;
    
    int256 private _holderRedistributionAmount = 10**18; // Amount to multiply final balances by
    
    int256 private _privateRedistributionAmount = 0; // Amount to add to balances
    
    // Constructor
    constructor() {}
    
    // Initialization Functions
    function setName(string name) public onlyOwner {
        this._name = name;
    }
    
    function setSymbol(string symbol) public onlyOwner {
        this._symbol = symbol;
    }
    
    function setRedistributionForAddress(address recipient, int256 redistribution) public onlyOwner {
        int256 redistributionChange = redistribution - this._privateRedistribution[recipient];
        this._totalRedistribution += redistributionChange;
        this._totalPrivateRedistribution += redistributionChange;
        this._privateRedistribution[recipient] = redistribution;
    }
    
    function setRedistributionForHolders(int256 redistribution) public onlyOwner {
        int256 redistributionChange = redistribution - this._holderRedistribution;
        this._totalRedistribution += redistributionChange;
        this._baseRedistribution = redistribution;
    }
    
    function setAmountTransferred(int256 distribution) public onlyOwner {
        int256 distributionChange = distribution - this._transferDistribution;
        this._totalRedistribution += distributionChange;
        this._transferDistribution = distribution;
    }
    
    function setBalance(address recipient, int256 amount) public onlyOwner {
        int256 supplyChange = amount - _balances[recipient];
        this._totalSupply += supplyChange;
        this._balances[recipient] = amount;
    }
    
    // Custom Getters for Custom Initialization
    function name() public view returns (string memory) {
        return this._name;
    }
    
    function symbol() public view returns (string memory) {
        return this._symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return 18;
    }
    
    // Custom Getters for ERC20 Properties
    function totalSupply() public view returns (uint256) {
        return this.toUint256(_totalSupply);
    }
    
    function balanceOf(address holder) public view returns (uint256 balance) {
        bytes16 originalOwnerBalance = this.fromInt(this._balances[holder]);
        bytes16 privateRedistributionAddon = this.div(this.mul(this.fromInt(this._privateRedistributionAmount), this.fromInt(this._privateRedistribution[holder])), this.fromInt(this._totalPrivateRedistribution));
        bytes16 holderMultiplier = this.div(this.fromInt(this._holderRedistributionAmount), this.fromInt(10 ** 18));
        return this.toUint256(this.toInt(this.mul(this.add(originalOwnerBalance, privateRedistributionAddon), holderRedistributionMultiplier)));
    }
    
    function allowance(address holder, address spender) public view returns (uint256 remaining) {
        return this.toUint256(this._allowances[holder][spender]);
    }
    
    // Custom Methods for ERC20 Properties
    function transfer(address to, uint256 value) public returns (bool success) {
        bytes16 holderMultiplier = this.div(this.fromInt(this._holderRedistributionAmount), this.fromInt(10 ** 18));
        bytes16 holderRedistributionMultiplier = this.div(this.fromInt(this._holderRedistribution), this.fromInt(10 ** 18));
        bytes16 privateRedistributionMultiplier = this.div(this.fromInt(this._totalPrivateRedistribution), this.fromInt(10 ** 18));
        bytes16 realDistributionMultiplier = this.div(this.fromInt(this._transferDistribution), this.fromInt(10 ** 18));
        bytes16 correctedValue = this.div(this.fromUInt(value), holderMultiplier);
        this._balances[msg.sender] -= this.toInt(correctedValue);
        this._balances[to] += this.mul(correctedValue, realDistributionMultiplier);
        this._privateRedistributionAmount += this.mul(correctedValue, privateRedistributionMultiplier);
        this._totalSupply = this.toInt(this.div(this.mul(correctedValue, this.fromInt(this._totalRedistribution)), this.fromInt(10 ** 18)));
        this._holderRedistributionAmount = this.toInt(this.div(this.mul(this.fromInt(this._holderRedistributionAmount), correctedValue), _totalSupply));
        emit Transfer(msg.sender, to, value);
        balanceOf(msg.sender); // Reverts if < 0
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        bytes16 holderMultiplier = this.div(this.fromInt(this._holderRedistributionAmount), this.fromInt(10 ** 18));
        bytes16 holderRedistributionMultiplier = this.div(this.fromInt(this._holderRedistribution), this.fromInt(10 ** 18));
        bytes16 privateRedistributionMultiplier = this.div(this.fromInt(this._totalPrivateRedistribution), this.fromInt(10 ** 18));
        bytes16 realDistributionMultiplier = this.div(this.fromInt(this._transferDistribution), this.fromInt(10 ** 18));
        bytes16 correctedValue = this.div(this.fromUInt(value), holderMultiplier);
        this._allowances[from][msg.sender] -= this.toInt(correctedValue);
        this._balances[from] -= this.toInt(correctedValue);
        this._balances[to] += this.mul(correctedValue, realDistributionMultiplier);
        this._privateRedistributionAmount += this.mul(correctedValue, privateRedistributionMultiplier);
        this._totalSupply = this.toInt(this.div(this.mul(correctedValue, this.fromInt(this._totalRedistribution)), this.fromInt(10 ** 18)));
        this._holderRedistributionAmount = this.toInt(this.div(this.mul(this.fromInt(this._holderRedistributionAmount), correctedValue), _totalSupply));
        emit Transfer(from, to, value);
        allowance(from, msg.sender); // Reverts if < 0
        balanceOf(from); // Reverts if < 0
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        this._allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
