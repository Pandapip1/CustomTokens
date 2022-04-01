// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./TokenContractPointer.sol";

contract ERC20Proxied is Multicall, ERC2771Context {
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);

    // Pointer
    LogicContractPointer public _ptr;
    
    // Constructor
    constructor(LogicContractPointer pointer, address trustedForwarder) ERC2771Context(trustedForwarder) {
        _ptr = pointer;
    }
    
    // Custom Getters
    function name() public view returns (string memory) {
        return _ptr._ptr.name();
    }
    
    function symbol() public view returns (string memory) {
        return  _ptr._ptr.symbol();
    }
    
    function decimals() public pure returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view returns (uint256) {
        return  _ptr._ptr.totalSupply();
    }
    
    function balanceOf(address holder) public view returns (uint256 balance) {
        return _ptr._ptr.balanceOf(holder);
    }
    
    function allowance(address holder, address spender) public view returns (uint256 remaining) {
        return _ptr._ptr.allowance(holder, spender);
    }
    
    // Custom Methods for ERC20 Properties
    function transfer(address to, uint256 value) public returns (bool success) {
        _ptr._ptr.transfer(_msgSender(), to, value);
        emit Transfer(_msgSender(), to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        _ptr._ptr.transferFrom(from, to, value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        _ptr.approve(_msgSender(), spender, value);
        emit Approval(msg.sender, spender, value);
        return true;
    }
}
