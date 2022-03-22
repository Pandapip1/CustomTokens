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
    
    mapping(address => int256) private _privateRedistribution;
    int256 private _holderRedistribution = 0;
    int256 private _transferDistribution = 0;
    
    // Derived Config
    int256 private _totalRedistribution = 0;
    
    int256 private _totalPrivateRedistribution = 0;
    
    // State
    mapping(address => int256) private _balances; // Standard ERC20 stuff
    mapping(address => mapping(address => uint256)) private _allowances; // More standard ERC20 stuff
    int256 private _totalSupply = 0;
    
    int256 private _holderRedistributionAmount = 10**18; // Amount to multiply final balances by
    
    int256 private _privateRedistributionAmount = 0; // Amount to add to balances
    
    // Constructor
    constructor() {}
    
    // Initialization Functions
    function setName(string memory name) public onlyOwner {
        _name = name;
    }
    
    function setSymbol(string memory symbol) public onlyOwner {
        _symbol = symbol;
    }
    
    function setRedistributionForAddress(address recipient, int256 redistribution) public onlyOwner {
        int256 redistributionChange = redistribution - _privateRedistribution[recipient];
        _totalRedistribution += redistributionChange;
        _totalPrivateRedistribution += redistributionChange;
        _privateRedistribution[recipient] = redistribution;
    }
    
    function setRedistributionForHolders(int256 redistribution) public onlyOwner {
        int256 redistributionChange = redistribution - _holderRedistribution;
        _totalRedistribution += redistributionChange;
        _holderRedistribution = redistribution;
    }
    
    function setAmountTransferred(int256 distribution) public onlyOwner {
        int256 distributionChange = distribution - _transferDistribution;
        _totalRedistribution += distributionChange;
        _transferDistribution = distribution;
    }
    
    function setBalance(address recipient, int256 amount) public onlyOwner {
        int256 supplyChange = amount - _balances[recipient];
        _totalSupply += supplyChange;
        _balances[recipient] = amount;
    }
    
    // Custom Getters for Custom Initialization
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns (uint8) {
        return 18;
    }
    
    // Custom Getters for ERC20 Properties
    function totalSupply() public view returns (uint256) {
        return _totalSupply.toUint256();
    }
    
    function balanceOf(address holder) public view returns (uint256 balance) {
        bytes16 originalOwnerBalance = _balances[holder].fromInt();
        bytes16 privateRedistributionAddon = _privateRedistributionAmount.fromInt().mul(_privateRedistribution[holder].fromInt()).div(_totalPrivateRedistribution.fromInt());
        bytes16 holderMultiplier = _holderRedistributionAmount.fromInt().div((10 ** 18).fromInt());
        return originalOwnerBalance.add(privateRedistributionAddon).mul(holderMultiplier).toUInt();
    }
    
    function allowance(address holder, address spender) public view returns (uint256 remaining) {
        return _allowances[holder][spender];
    }
    
    // Custom Methods for ERC20 Properties
    function transfer(address to, uint256 value) public returns (bool success) {
        bytes16 holderMultiplier = _holderRedistributionAmount.fromInt().div((10 ** 18).fromInt());
        bytes16 holderRedistributionMultiplier = _holderRedistribution.fromInt().div((10 ** 18).fromInt());
        bytes16 privateRedistributionMultiplier = _totalPrivateRedistribution.fromInt().div((10 ** 18).fromInt());
        bytes16 realDistributionMultiplier = _transferDistribution.fromInt().div((10 ** 18).fromInt());
        bytes16 correctedValue = value.fromUInt().div(holderMultiplier);
        _balances[msg.sender] -= correctedValue.toInt();
        _balances[to] += correctedValue.mul(realDistributionMultiplier).toInt();
        _privateRedistributionAmount += correctedValue.mul(privateRedistributionMultiplier).toInt();
        _totalSupply = correctedValue.mul(_totalRedistribution.fromInt()).div((10 ** 18).fromInt()).toInt();
        _holderRedistributionAmount = _holderRedistributionAmount.fromInt().mul(correctedValue).div(_totalSupply.fromInt()).toInt();
        emit Transfer(msg.sender, to, value);
        balanceOf(msg.sender); // Reverts if < 0
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        bytes16 holderMultiplier = _holderRedistributionAmount.fromInt().div((10 ** 18).fromInt());
        bytes16 holderRedistributionMultiplier = _holderRedistribution.fromInt().div((10 ** 18).fromInt());
        bytes16 privateRedistributionMultiplier = _totalPrivateRedistribution.fromInt().div((10 ** 18).fromInt());
        bytes16 realDistributionMultiplier = _transferDistribution.fromInt().div((10 ** 18).fromInt());
        bytes16 correctedValue = value.fromUInt().div(holderMultiplier);
        _allowances[from][msg.sender] -= correctedValue.toUInt();
        _balances[from] -= correctedValue.toInt();
        _balances[to] += correctedValue.mul(realDistributionMultiplier).toInt();
        _privateRedistributionAmount += correctedValue.mul(privateRedistributionMultiplier).toInt();
        _totalSupply = correctedValue.mul(_totalRedistribution.fromInt()).div((10 ** 18).fromInt()).toInt();
        _holderRedistributionAmount = _holderRedistributionAmount.fromInt().mul(correctedValue).div(_totalSupply.fromInt()).toInt();
        emit Transfer(from, to, value);
        allowance(from, msg.sender); // Reverts if < 0
        balanceOf(from); // Reverts if < 0
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
