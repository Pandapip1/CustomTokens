// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title                      An extension of ERC20 that can scale every user's tokens
/// @author                     Pandapip1 (@Pandapip1)
/// @notice                     Multiplies every user's balance by a certain amount, and redoes the transfer calculations
abstract contract ERC20Scalable is ERC20 {

    ///////////////
    //// STATE ////
    ///////////////

    /// @notice                 The scaling factor is the denominator of the fraction that is used for scaling
    /// @dev                    Make sure to use this to determine what to pass to _setScaling, as it might change!
    /// @return                 The scaling factor
    uint256 immutable public scalingFactor = 10 ** 54;

    /// @notice                 This is the numerator of the fraction that is used for scaling
    /// @dev                    Use _setScaling to modify this. Pay attention to the scaling factor!
    uint256 private _scaling;

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice                 Emitted when _scaling changes
    /// @dev                    Emitted by _setScaling. Do not emit yourself unless you know what you're doing.
    /// @param  newScaling      The new value of _scaling
    /// @param  oldScaling      The old value of _scaling
    event Scaled(uint256 newScaling, uint256 oldScaling);

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
    function scaling() public virtual view returns (uint256 scalingAmt) {
        return _scaling;
    }

    /// @notice                 Sets _scaling
    /// @dev                    Make sure to pay attention to scalingFactor
    /// @param  scalingAmt      The value of _scaling
    function _setScaling(uint256 scalingAmt) internal virtual {
        require(scalingAmt > 0, "Scaling must be positive");
        emit Scaled(scalingAmt, _scaling);
        _scaling = scalingAmt;
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

    function totalSupply() public virtual override view returns (uint256 amount) {
        return super.totalSupply() * _scaling / scalingFactor;        
    }

    function balanceOf(address holder) public virtual override view returns (uint256 amount) {
        return super.balanceOf(holder) * _scaling / scalingFactor;        
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        super._transfer(from, to, amount * scalingFactor / _scaling);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount * scalingFactor / _scaling);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount * scalingFactor / _scaling);
    }
}