// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/// @title                  A variation of of ERC2771Context with support for multiple trusted forwarders
/// @author                 Pandapip1 (@Pandapip1)
/// @notice                 Used so that multiple Meta Transaction forwarders (like OpenGSN, OpenZeppelin Relay, and Biconomy) can all be used
/// @dev                    Use _setForwarder to set trusted forwarders
abstract contract MultiERC2771Context is Context {

    ///////////////
    //// STATE ////
    ///////////////

    /// @notice             Stores the trusted forwarders
    /// @dev                Don't modify this. Use _setForwarder and isTrustedForwarder instead
    mapping(address => bool) private _forwarders;

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice             Emitted when a trusted forwarder is added or removed
    /// @dev                Do not emit manually unless you know what you're doing. _setForwarder emits this automatically.
    /// @param  forwarder   The forwarder being updated
    /// @param  isForwarder Whether the forwarder is now trusted or removed
    event ForwarderUpdated(address forwarder, bool isForwarder);

    constructor() {} // Nothing needed

    /// @notice             Sets or unsets a trusted forwarder
    /// @dev                Call this to set or unset a forwarder
    /// @param  forwarder   The forwarder being updated
    /// @param  isForwarder Whether the forwarder is being trusted or removed
    function _setForwarder(address forwarder, bool isForwarder) internal virtual {
        _forwarders[forwarder] = isForwarder;
        emit ForwarderUpdated(forwarder, isForwarder);
    }

    /// @notice             Gets if an address is a forwarder
    /// @dev                Used in the validation
    /// @param  forwarder   The address to check
    /// @return isForwarder Returns whether or not the address is a forwarder
    function isTrustedForwarder(address forwarder) public view virtual returns (bool isForwarder) {
        return _forwarders[forwarder];
    }

    ///////////////////
    //// OVERRIDES ////
    ///////////////////

    /// @notice             Gets the address that sent this transaction
    /// @dev                Use this, NOT msg.sender
    /// @return sender      The real msg.sender
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    /// @notice             Gets the transaction data
    /// @dev                Use this, NOT msg.data
    /// @return sender      The real msg.data
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}