// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title                      An extension of ERC20 that adds holder redistribution
/// @author                     Pandapip1 (@Pandapip1)
/// @notice                     Multiplies every user's balance by a certain amount, and redoes the transfer calculations
abstract contract ERC20HolderDistribution is ERC20 {
    using Address for address;

    ///////////////
    //// STATE ////
    ///////////////

    /// @notice                 The scaling factor is the denominator of the fraction that is used for scaling
    uint256 immutable public scalingFactor = 10 ** 54;

    /// @notice                 This is the numerator of the fraction that is used for scaling
    uint256 private _scaling;

    /// @notice                 The holder distribution, out of 10 ** 18
    uint256 private _holderDistrib;

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice                 Emitted when _holderDistrib changes
    /// @dev                    Emitted automatically when _setHolderDistribution is called, no need to emit this yourself.
    /// @param  newDistrib      The new distribution
    /// @param  oldDistrib      The old distribution
    event HolderDistributionChanged(uint256 newDistrib, uint256 oldDistrib);

    /////////////////////
    //// CONSTRUCTOR ////
    /////////////////////

    constructor() {
        _scaling = scalingFactor;
    }

    ///////////////////
    //// FUNCTIONS ////
    ///////////////////

    /// @notice                 Get the value of scaling
    /// @return scalingAmt      Returns _scaling
    function scaling() public view returns (uint256 scalingAmt) {
        return _scaling;
    }

    /// @notice                 Get the holder distribution amount
    function holderDistribution() public virtual view returns (uint256 holderDistrib) {
        return _holderDistrib;
    }

    /// @notice                 Sets _scaling
    /// @param  scalingAmt      The value of _scaling
    function _setScaling(uint256 scalingAmt) internal virtual {
        require(scalingAmt > 0, "Scaling must be positive");
        _scaling = scalingAmt;
    }

    function _setHolderDistribution(uint256 theHolderDistribution) internal virtual {
        emit HolderDistributionChanged(theHolderDistribution, _holderDistrib);
        _holderDistrib = theHolderDistribution;
    }

    /// @notice                 Creates tokens and distributes them according to holders
    /// @param  tokensToAdd     Amount to create
    function _upscale(uint256 tokensToAdd) internal virtual {
        uint256 theTotalSupply = totalSupply();
        _setScaling(_scaling * (theTotalSupply + tokensToAdd) / theTotalSupply);
    }

    /// @notice                 Burns tokens according to holders
    /// @param  tokensToRemove  Amount to create
    function _downscale(uint256 tokensToRemove) internal virtual {
        require(tokensToRemove < totalSupply(), "Scaling must be positive");
        uint256 theTotalSupply = totalSupply();
        _setScaling(_scaling * (theTotalSupply - tokensToRemove) / theTotalSupply);
    }
    
    ///////////////////
    //// OVERRIDES ////
    ///////////////////

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (from != address(0) && to != address(0) && !(to.isContract() && !from.isContract())) {
            _upscale(amount * holderDistribution() / 10 ** 18);
        }
    }

    function totalSupply() public virtual override view returns (uint256 amount) {
        return super.totalSupply() * scaling() / scalingFactor;        
    }

    function balanceOf(address holder) public virtual override view returns (uint256 amount) {
        return super.balanceOf(holder) * scaling() / scalingFactor;        
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        super._transfer(from, to, amount * scalingFactor / scaling());
    }

    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount * scalingFactor / scaling());
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount * scalingFactor / scaling());
    }
}