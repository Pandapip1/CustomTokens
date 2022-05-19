// SPDX-License-Identifier: MIT
// https://github.com/Pandapip1/CustomTokens

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title                      An extension of ERC20 that adds private redistribution
/// @author                     Pandapip1 (@Pandapip1)
abstract contract ERC20PrivateDistribution is ERC20 {
    using Address for address;

    ///////////////
    //// STATE ////
    ///////////////

    /// @notice                 The indexes of _users and _dists
    /// @dev                    Use _setDistribution to modify this
    mapping(address => uint256) private _indexes;

    /// @notice                 The users to distribute to
    /// @dev                    Use _setDistribution to modify this
    address[] private _users;

    /// @notice                 The amount to distribute
    /// @dev                    Use _setDistribution to modify this
    uint256[] private _dists;

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice                 Emitted when _dists changes
    /// @dev                    Emitted by _setDistribution. Do not emit yourself unless you know what you're doing.
    /// @param  acct            The address whose distribution has changed
    /// @param  newDist         The new value of _fee
    /// @param  oldDist         The old value of _fee
    event DistributionChanged(address indexed acct, uint256 newDist, uint256 oldDist);

    /////////////////////
    //// CONSTRUCTOR ////
    /////////////////////

    constructor() {
        _dists.push(0);
        _users.push(address(0));
    }

    ///////////////////
    //// FUNCTIONS ////
    ///////////////////

    /// @notice                 Get the distribs
    /// @return users           Returns the users with a distribution
    /// @return dists           Returns the distribution amount for the user with an index
    function distributions() public virtual view returns (address[] memory users, uint256[] memory dists) {
        return (_users, _dists);
    }

    /// @notice                 Sets distribution
    /// @param  acct            The address to update
    /// @param  newDist         The new distribution
    function _setDistribution(address acct, uint256 newDist) internal virtual {
        require(acct != address(0), "Account cannot be the null address");
        if (_dists[_indexes[acct]] == 0) {
            _indexes[acct] = _dists.length;
            _users.push(acct);
            _dists.push(0);
        }
        emit DistributionChanged(acct, newDist, _dists[_indexes[acct]]);
        _dists[_indexes[acct]] = 0;
    }

    
    ///////////////////
    //// OVERRIDES ////
    ///////////////////

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (from != address(0) && to != address(0) && !(to.isContract() && !from.isContract())) {
            (address[] memory users, uint256[] memory dists) = distributions();
            for (uint256 i = 1; i < users.length; i++) {
                _mint(users[i], amount * dists[i] / 10 ** 18);
            }
        }
    }
}
