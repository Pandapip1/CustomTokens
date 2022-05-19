// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20PrivateDistribution.sol";
import "./ERC20HolderDistribution.sol";
import "./ERC20Fee.sol";

/// @title                      An extension of ERC20 that adds redistribution capabilities
/// @author                     Pandapip1 (@Pandapip1)
abstract contract ERC20Redistribution is ERC20HolderDistribution, ERC20PrivateDistribution, ERC20Fee {
    using Address for address;

    ///////////////
    //// STATE ////
    ///////////////

    ////////////////
    //// EVENTS ////
    ////////////////

    /////////////////////
    //// CONSTRUCTOR ////
    /////////////////////

    constructor() {
    }

    ///////////////////
    //// FUNCTIONS ////
    ///////////////////

    
    ///////////////////
    //// OVERRIDES ////
    ///////////////////
    function totalSupply() public override(ERC20HolderDistribution, ERC20) virtual view returns (uint256 supply) {
        return ERC20HolderDistribution.totalSupply();
    }

    function balanceOf(address holder) public override(ERC20HolderDistribution, ERC20) virtual view returns (uint256 balance) {
        return ERC20HolderDistribution.balanceOf(holder);
    }
    
    function _mint(address account, uint256 amount) internal override(ERC20HolderDistribution, ERC20) virtual {
        ERC20HolderDistribution._mint(account, amount);
    }
    
    function _burn(address account, uint256 amount) internal override(ERC20HolderDistribution, ERC20) virtual {
        ERC20HolderDistribution._burn(account, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) internal override(ERC20HolderDistribution, ERC20) virtual {
        ERC20HolderDistribution._transfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20HolderDistribution, ERC20PrivateDistribution, ERC20Fee) virtual {
        // The order in which this should be run:
        // 1: Private Distribution should occur
        // 2: Holder Distribution should occur
        // 3: Fee should be taken
        if (from != address(0) && to != address(0) && !(to.isContract() && !from.isContract())) {
            (address[] memory users, uint256[] memory dists) = distributions();
            for (uint256 i = 1; i < users.length; i++) {
                ERC20._mint(users[i], amount * dists[i] / 10 ** 18);
            }
            _upscale(amount * holderDistribution() / 10 ** 18 * scaling() / scalingFactor);
            _burn(to, amount * fee() / 10 ** 18);
        }
        ERC20._afterTokenTransfer(from, to, amount);
    }
}
