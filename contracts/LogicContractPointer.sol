// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenLogicContract.sol";

contract TokenContractPointer is Ownable, ERC2771Context {
    // Events
    event Point(address indexed _old, address indexed _new);

    // State
    TokenLogicContract public _ptr;
    
    // Constructor
    constructor(TokenLogicContract logic, address trustedForwarder) ERC2771Context(trustedForwarder) {
        emit Point(address(0), address(logic));
        _ptr = logic;
    }

    // Method
    function point(TokenLogicContract logic) public onlyOwner {
        emit Point(_ptr, logic);
        _ptr = logic;
    }
}
