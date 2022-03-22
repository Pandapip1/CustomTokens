// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomizableERC777 is ERC777, Multicall, Ownable {
    // State
    string private _name = "Uninitialized Token";
    string private _symbol = "UNINIT";
    
    mapping(address => uint256) private _redistribution;
    uint256 private _baseRedistribution;
    uint256 private _totalRedistribution;
    
    // Constructor with sensible defaults
    constructor() ERC777("", "", []) {}
    
    // Initialization Functions
    function setName(string name) public onlyOwner {
        _name = name;
    }
    
    function setSymbol(string symbol) public onlyOwner {
        _symbol = symbol;
    }
    
    function setRedistributionForAddress(address recipient, uint256 redistribution) public onlyOwner {
        _totalRedistribution = _totalRedistribution - _redistribution[recipient] + redistribution;
        _redistribution[recipient] = redistribution;
    }
    
    function setRedistributionForHolders(uint256 redistribution) public onlyOwner {
        _totalRedistribution = _totalRedistribution - _baseRedistribution + redistribution;
        _baseRedistribution = redistribution;
    }
    
    function mint(address recipient, uint256 amount) public onlyOwner {
        _mint(recipient, initialSupply, "", "");
    }
    
    // Custom Getters for Custom Initialization
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
}
