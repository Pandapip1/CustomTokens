// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/v3.0/ABDKMathQuad.sol";

contract TokenLogicContract is Multicall, Ownable, ERC2771Context {
    // Libraries
    using SafeCast for *;
    using ABDKMathQuad for *;
    
    // Config
    mapping(uint256 => string) public _name;
    mapping(uint256 => string) public _symbol;
    
    mapping(uint256 => mapping(address => uint256)) public _privateDistribution;
    mapping(uint256 => uint256) public _totalPrivateDistribution = 0;
    mapping(uint256 => uint256) public _holderDistribution = 0;
    mapping(uint256 => uint256) public _transferDistribution = 0;
    
    // State

    uint256 public _nextTokenId;

    mapping(uint256 => address) public _owners;
    mapping(uint256 => bool) public _doesTokenExist;

    mapping(uint256 => mapping(address => uint256)) public _balances; // Standard ERC20 stuff
    mapping(uint256 => mapping(address => uint256)) public _balanceDebts;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public _allowances; // More standard ERC20 stuff
    mapping(uint256 => uint256) public _totalSupply = 0;
    
    mapping(uint256 => uint256) public _holderDistributionAmount = 10**18; // Amount to multiply final balances by
    
    mapping(uint256 => uint256) public _privateDistributionAmount = 0; // Amount to add to balances

    bool public _hasParent;
    bool public _isWaitingOnParent;
    TokenLogicContract public _parent;
    bool public _isFrozen;
    
    mapping(uint256 => bool) _tokenMetaLoaded;
    mapping(uint256 => mapping(address => bool)) _tokenBalanceLoaded;
    mapping(uint256 => mapping(address => mapping(address => bool))) _tokenAllowanceLoaded;

    // Modifier
    modifier onlyTokenOwner(uint256 tokenId) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        require(_msgSender() == parent._owners[tokenId]);
        _;
    }

    modifier onlyTokenInitialized(uint256 tokenId) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        require(parent._owners[tokenId] == address(0) && parent._doesTokenExist[tokenId]);
        _;
    }

    modifier onlyUnlocked {
        // Waiting on parent checks
        if (_hasParent && _isWaitingOnParent) {
            if (_parent._isFrozen) {
                _isWaitingOnParent = false;
                // It's time to store dat state!
                _nextTokenId = _parent._nextTokenId;
                // Oh... that was anticlimactic
                // The rest is done completely lazily
            }
        }
        require(!_isWaitingOnParent && !_isFrozen);
        _;
    }

    modifier updateTokenParent(uint256 tokenId) {
        // Waiting on parent checks
        if (_hasParent && !_isWaitingOnParent && !_tokenMetaLoaded[tokenId]) {
            TokenLogicContract parent = _parent;
            while (address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
                parent = parent._parent;
            }
            _tokenMetaLoaded[tokenId] = true;
            if (address(parent) != address(0)) {
                _name[tokenId] = parent._name[tokenId];
                _symbol[tokenId] = parent._symbol[tokenId];
                _owners[tokenId] = parent._owners[tokenId];
                _doesTokenExist[tokenId] = parent._doesTokenExist[tokenId];
                _totalPrivateDistribution[tokenId] = parent._totalPrivateDistribution[tokenId];
                _holderDistribution[tokenId] = parent._holderDistribution[tokenId];
                _transferDistribution[tokenId] = parent._transferDistribution[tokenId];
                _totalSupply[tokenId] = parent._totalSupply[tokenId];
                _holderDistributionAmount[tokenId] = parent._holderDistributionAmount[tokenId];
                _privateDistributionAmount[tokenId] = parent._privateDistributionAmount[tokenId];
            }
        }
        _;
    }

    modifier updateTokenHolder(uint256 tokenId, address holder) {
        // Waiting on parent checks
        if (_hasParent && !_isWaitingOnParent && !_tokenBalanceLoaded[tokenId][holder]) {
            TokenLogicContract parent = _parent;
            while (address(parent) != address(0) && !parent._tokenBalanceLoaded[tokenId][holder]) {
                parent = parent._parent;
            }
            _tokenBalanceLoaded[tokenId][holder] = true;
            if (address(parent) != address(0)) {
                _balances[tokenId][holder] = parent._balances[tokenId][holder];
                _balanceDebts[tokenId][holder] = parent._balanceDebts[tokenId][holder];
                _privateDistribution[tokenId][holder] = parent._privateDistribution[tokenId][holder];
            }
        }
        _;
    }

    modifier updateTokenAllowance(uint256 tokenId, address holder, address executor) {
        // Waiting on parent checks
        if (_hasParent && !_isWaitingOnParent && !_tokenAllowanceLoaded[tokenId][holder][executor]) {
            TokenLogicContract parent = _parent;
            while (address(parent) != address(0) && !parent._tokenAllowanceLoaded[tokenId]) {
                parent = parent._parent;
            }
            _tokenAllowanceLoaded[tokenId][holder][executor] = true;
            if (address(parent) != address(0)) {
                _allowances[tokenId][holder][executor] = parent._allowances[tokenId][holder][executor];
            }
        }
        _;
    }
    
    // Constructor
    constructor (address parent, address trustedForwarder) ERC2771Context(trustedForwarder) {
        if (parent != address(0)) {
            _hasParent = true;
            _parent = TokenLogicContract(parent);
            _isWaitingOnParent = !_parent._isFrozen;
        } else {
            _hasParent = false;
            _isWaitingOnParent = false;
        }
    }

    // Upgradeability
    function freeze() public onlyOwner {
        _isFrozen = true;
    }
    
    // Initialization Functions
    function createToken() public onlyUnlocked returns (uint256) {
        _doesTokenExist[_nextTokenId] = true;
        _owners[_nextTokenId] = _msgSender();
        _nextTokenId += 1;
        return _nextTokenId - 1;
    }

    function setName(uint256 tokenId, string memory newName) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _name[tokenId] = newName;
    }
    
    function setSymbol(uint256 tokenId, string memory newSymbol) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _symbol[tokenId] = newSymbol;
    }
    
    function setDistributionForAddress(uint256 tokenId, address recipient, uint256 distribution) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _totalPrivateDistribution[tokenId] += distribution;
        _totalPrivateDistribution[tokenId] -= _privateDistribution[recipient];

        _privateDistribution[tokenId][recipient] = distribution;
    }
    
    function setDistributionForHolders(uint256 tokenId, uint256 distribution) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _holderDistribution[tokenId] = distribution;
    }
    
    function setAmountTransferred(uint256 tokenId, uint256 distribution) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _transferDistribution[tokenId] = distribution;
    }
    
    function setBalance(uint256 tokenId, address recipient, int256 amount) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _totalSupply[tokenId] += amount;
        _totalSupply[tokenId] -= _balances[recipient];
        
        _balances[tokenId][recipient] = amount;
    }

    function finalize(uint256 tokenId) public onlyUnlocked updateTokenParent(tokenId) onlyTokenOwner(tokenId) {
        _owners[tokenId] = address(0);
    }
    
    // Custom Getters for Custom Initialization
    function name(uint256 tokenId) public view onlyTokenInitialized(tokenId) returns (string memory) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        return parent._name[tokenId];
    }
    
    function symbol(uint256 tokenId) public view onlyTokenInitialized(tokenId) returns (string memory) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        return parent._symbol[tokenId];
    }

    // Helpers (these use "true tokens")
    function _getTrueDistributionAmount(uint256 amount, uint256 scale) internal pure returns (uint256) {
        return amount.fromUInt().mul(scale.fromUInt()).div((10 ** 18).fromUInt()).toUInt();
    }

    function _getTrueBalance(uint256 tokenId, address holder) internal view onlyTokenInitialized(tokenId) returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenBalanceLoaded[tokenId][holder]) {
            parent = parent._parent;
        }
        return parent._balances[tokenId][toGet] + parent._getTrueDistributionAmount(parent._privateDistributionAmount[tokenId], parent._privateDistribution[tokenId][holder]) - parent._balanceDebts[tokenId][toGet];
    }

    function _distributeTruePrivate(uint256 tokenId, uint256 amount) internal onlyTokenInitialized(tokenId) {
        _privateDistributionAmount[tokenId] += amount;
        _totalSupply[tokenId] += amount;
    }

    function _distributeTrueHolders(uint256 tokenId, uint256 amount) internal onlyTokenInitialized(tokenId) {
        _holderDistributionAmount[tokenId] = _holderDistributionAmount[tokenId].fromUInt().mul(amount.fromUInt().mul(_totalSupply[tokenId].fromUInt())).toUInt();
        _totalSupply[tokenId] += amount;
    }

    function _simplifyTrueDebts(uint256 tokenId, address toSimplify) internal onlyTokenInitialized(tokenId) {
        if (_balances[tokenId][toSimplify] > _balanceDebts[tokenId][toSimplify]) {
            _balances[tokenId][toSimplify] -= balanceDebts[tokenId][toSimplify];
            _balanceDebts[tokenId][toSimplify] = 0;
        } else {
            _balanceDebts[tokenId][toSimplify] -= _balances[tokenId][toSimplify];
            _balances[tokenId][toSimplify] = 0;
        }
    }

    function _subtractTrueBalance(uint256 tokenId, address from, uint256 amount) internal onlyTokenInitialized(tokenId) {
        require(_getTrueBalance(tokenId, from) > amount, "User doesn't have enough balance");
        
        _balanceDebts[tokenId][from] += amount;
        _totalSupply[tokenId] -= amount;
        _simplifyTrueDebts(tokenId, from);
    }

    function _addTrueBalance(uint256 tokenId, address to, uint256 amount) internal onlyTokenInitialized(tokenId) {
        _balances[tokenId][to] += amount;
        _totalSupply[tokenId] += amount;
        _simplifyTrueDebts(tokenId, to);
    }

    function _transferTrue(uint256 tokenId, address from, address to, uint256 amount) internal onlyTokenInitialized(tokenId) {
        _subtractTrueBalance(tokenId, from, amount);
        _addTrueBalance(tokenId, to, _getTrueDistributionAmount(amount, _transferDistribution[tokenId]));
        _distributeTruePrivate(tokenId, _getTrueDistributionAmount(amount, _totalPrivateDistribution[tokenId]));
        _distributeTrueHolders(tokenId, _getTrueDistributionAmount(amount, _holderDistribution[tokenId]));
    }

    // Helpers
    function _trueToVisible(uint256 tokenId, uint256 amount) internal view onlyTokenInitialized(tokenId) returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        return parent._getTrueDistributionAmount(amount, parent._holderDistributionAmount[tokenId]);
    }
    
    function _visibleToTrue(uint256 tokenId, uint256 amount) internal view onlyTokenInitialized(tokenId) returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        // Can't be simplified :(
        return amount.fromUInt().mul((10 ** 18).fromUInt()).div(parent._holderDistributionAmount[tokenId]).toUInt();
    }

    // Custom Getters for ERC20 Properties
    function totalSupply(uint256 tokenId) public view onlyTokenInitialized(tokenId) returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[tokenId]) {
            parent = parent._parent;
        }
        return parent._trueToVisible(tokenId, parent._totalSupply);
    }
    
    function balanceOf(uint256 tokenId, address holder) public view onlyTokenInitialized(tokenId) returns (uint256 balance) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenBalanceLoaded[tokenId][holder]) {
            parent = parent._parent;
        }
        return parent._trueToVisible(tokenId, parent._getTrueBalance(tokenId, holder));
    }
    
    function allowance(uint256 tokenId, address holder, address spender) public view onlyTokenInitialized(tokenId) returns (uint256 remaining) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenAllowanceLoaded[tokenId][holder][spender]) {
            parent = parent._parent;
        }
        return parent._allowances[tokenId][holder][spender];
    }
    
    // Custom Methods for ERC20 Properties
    function transfer(uint256 tokenId, address to, uint256 value) public onlyUnlocked updateTokenParent(tokenId) updateTokenHolder(tokenId, _msgSender()) updateTokenHolder(tokenId, to) onlyTokenInitialized(tokenId) returns (bool success) {
        _transferTrue(tokenId, _msgSender(), to, _visibleToTrue(tokenId, value));
        return true;
    }
    
    function transferFrom(uint256 tokenId, address from, address to, uint256 value) public onlyUnlocked updateTokenParent(tokenId) updateTokenHolder(tokenId, from) updateTokenHolder(tokenId, to) updateTokenAllowance(tokenId, from, _msgSender()) onlyTokenInitialized(tokenId) returns (bool success) {
        require(_allowances[tokenId][_msgSender()][from] >= value, "Not enough allowance");

        _allowances[tokenId][_msgSender()][from] -= value;
        _transferTrue(tokenId, from, to, _visibleToTrue(tokenId, value));
        return true;
    }
    
    function approve(uint256 tokenId, address spender, uint256 value) public onlyUnlocked updateTokenParent(tokenId) updateTokenHolder(tokenId, spender) updateTokenAllowance(tokenId, _msgSender(), spender) onlyTokenInitialized(tokenId) returns (bool success) {
        _allowances[tokenId][_msgSender()][spender] = value;
        return true;
    }
}
