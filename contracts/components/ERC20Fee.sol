// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title                      An extension of ERC20 that adds a percentage transaction fee
/// @author                     Pandapip1 (@Pandapip1)
/// @notice                     When sending from an EOA to a smart contract, there will be no transaction fee
abstract contract ERC20Fee is ERC20 {
    using Address for address;

    ///////////////
    //// STATE ////
    ///////////////

    /// @notice                 The fee (out of 10 ** 18)
    /// @dev                    Use _setFee to modify this
    uint256 private _fee;

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice                 Emitted when _fee changes
    /// @dev                    Emitted by _setFee. Do not emit yourself unless you know what you're doing.
    /// @param  newFee          The new value of _fee
    /// @param  oldFee          The old value of _fee
    event FeeUpdated(uint256 newFee, uint256 oldFee);

    /////////////////////
    //// CONSTRUCTOR ////
    /////////////////////

    constructor() {
        _fee = 0;
    }

    ///////////////////
    //// FUNCTIONS ////
    ///////////////////

    /// @notice                 Get the value of _fee
    /// @return feeAmt          Returns _fee
    function fee() public virtual view returns (uint256 feeAmt) {
        return _fee;
    }

    /// @notice                 Sets _fee
    /// @param  newFee          The value of _fee
    function _setFee(uint256 newFee) internal virtual {
        require(newFee < 10 ** 18, "Fee must be less than one");
        emit FeeUpdated(newFee, fee());
        _fee = newFee;
    }

    
    ///////////////////
    //// OVERRIDES ////
    ///////////////////

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (from != address(0) && to != address(0) && !(to.isContract() && !from.isContract())) {
            _burn(to, amount * fee() / 10 ** 18);
        }
    }
}