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
    mapping(address => string) public _name;
    mapping(address => string) public _symbol;
    
    mapping(address => mapping(address => uint256)) public _privateDistribution;
    mapping(address => uint256) public _totalPrivateDistribution = 0;
    mapping(address => uint256) public _holderDistribution = 0;
    mapping(address => uint256) public _transferDistribution = 0;
    
    // State
    mapping(address => bool) public _initialized;

    mapping(address => mapping(address => uint256)) public _balances; // Standard ERC20 stuff
    mapping(address => mapping(address => uint256)) public _balanceDebts;
    mapping(address => mapping(address => mapping(address => uint256))) public _allowances; // More standard ERC20 stuff
    mapping(address => uint256) public _totalSupply = 0;
    
    mapping(address => uint256) public _holderDistributionAmount = 10**18; // Amount to multiply final balances by
    
    mapping(address => uint256) public _privateDistributionAmount = 0; // Amount to add to balances

    bool public _hasParent;
    bool public _isWaitingOnParent;
    TokenLogicContract public _parent;
    bool public _isFrozen;
    
    mapping(address => bool) _tokenMetaLoaded;
    mapping(address => mapping(address => bool)) _tokenBalanceLoaded;
    mapping(address => mapping(address => mapping(address => bool))) _tokenAllowanceLoaded;

    // Modifier
    modifier onlyTokenOwner {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        require(!parent._initialized[_msgSender()]);
        _;
    }

    modifier onlyTokenInitialized {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        require(parent._initialized[_msgSender()]);
        _;
    }

    modifier onlyUnlocked {
        // Waiting on parent checks
        if (_hasParent && _isWaitingOnParent) {
            if (_parent._isFrozen) {
                _isWaitingOnParent = false;
            }
        }
        require(!_isWaitingOnParent && !_isFrozen);
        _;
    }

    modifier updateTokenParent {
        // Waiting on parent checks
        if (_hasParent && !_isWaitingOnParent && !_tokenMetaLoaded[_msgSender()]) {
            TokenLogicContract parent = _parent;
            while (address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
                parent = parent._parent;
            }
            _tokenMetaLoaded[_msgSender()] = true;
            if (address(parent) != address(0)) {
                _name[_msgSender()] = parent._name[_msgSender()];
                _symbol[_msgSender()] = parent._symbol[_msgSender()];
                _initialized[_msgSender()] = parent._initialized[_msgSender()];
                _doesTokenExist[_msgSender()] = parent._doesTokenExist[_msgSender()];
                _totalPrivateDistribution[_msgSender()] = parent._totalPrivateDistribution[_msgSender()];
                _holderDistribution[_msgSender()] = parent._holderDistribution[_msgSender()];
                _transferDistribution[_msgSender()] = parent._transferDistribution[_msgSender()];
                _totalSupply[_msgSender()] = parent._totalSupply[_msgSender()];
                _holderDistributionAmount[_msgSender()] = parent._holderDistributionAmount[_msgSender()];
                _privateDistributionAmount[_msgSender()] = parent._privateDistributionAmount[_msgSender()];
            }
        }
        _;
    }

    modifier updateTokenHolder(address holder) {
        // Waiting on parent checks
        if (_hasParent && !_isWaitingOnParent && !_tokenBalanceLoaded[_msgSender()][holder]) {
            TokenLogicContract parent = _parent;
            while (address(parent) != address(0) && !parent._tokenBalanceLoaded[_msgSender()][holder]) {
                parent = parent._parent;
            }
            _tokenBalanceLoaded[_msgSender()][holder] = true;
            if (address(parent) != address(0)) {
                _balances[_msgSender()][holder] = parent._balances[_msgSender()][holder];
                _balanceDebts[_msgSender()][holder] = parent._balanceDebts[_msgSender()][holder];
                _privateDistribution[_msgSender()][holder] = parent._privateDistribution[_msgSender()][holder];
            }
        }
        _;
    }

    modifier updateTokenAllowance(address holder, address executor) {
        // Waiting on parent checks
        if (_hasParent && !_isWaitingOnParent && !_tokenAllowanceLoaded[_msgSender()][holder][executor]) {
            TokenLogicContract parent = _parent;
            while (address(parent) != address(0) && !parent._tokenAllowanceLoaded[_msgSender()]) {
                parent = parent._parent;
            }
            _tokenAllowanceLoaded[_msgSender()][holder][executor] = true;
            if (address(parent) != address(0)) {
                _allowances[_msgSender()][holder][executor] = parent._allowances[_msgSender()][holder][executor];
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
    function createToken() public onlyUnlocked {
        _doesTokenExist[_msgSender()] = true;
        _owners[_msgSender()] = _msgSender();
    }

    function setName(string memory newName) public onlyUnlocked updateTokenParent onlyTokenOwner {
        _name[_msgSender()] = newName;
    }
    
    function setSymbol(string memory newSymbol) public onlyUnlocked updateTokenParent onlyTokenOwner {
        _symbol[_msgSender()] = newSymbol;
    }
    
    function setDistributionForAddress(address recipient, uint256 distribution) public onlyUnlocked updateTokenParent onlyTokenOwner {
        _totalPrivateDistribution[_msgSender()] += distribution;
        _totalPrivateDistribution[_msgSender()] -= _privateDistribution[recipient];

        _privateDistribution[_msgSender()][recipient] = distribution;
    }
    
    function setDistributionForHolders(uint256 distribution) public onlyUnlocked updateTokenParent onlyTokenOwner {
        _holderDistribution[_msgSender()] = distribution;
    }
    
    function setAmountTransferred(uint256 distribution) public onlyUnlocked updateTokenParent onlyTokenOwner {
        _transferDistribution[_msgSender()] = distribution;
    }
    
    function setBalance(address recipient, int256 amount) public onlyUnlocked updateTokenParent onlyTokenOwner {
        _totalSupply[_msgSender()] += amount;
        _totalSupply[_msgSender()] -= _balances[recipient];
        
        _balances[_msgSender()][recipient] = amount;
    }

    function finalize() public onlyUnlocked updateTokenParent onlyTokenOwner {
        _owners[_msgSender()] = address(0);
    }
    
    // Custom Getters for Custom Initialization
    function name() public view onlyTokenInitialized returns (string memory) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        return parent._name[_msgSender()];
    }
    
    function symbol() public view onlyTokenInitialized returns (string memory) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        return parent._symbol[_msgSender()];
    }

    // Helpers (these use "true tokens")
    function _getTrueDistributionAmount(uint256 amount, uint256 scale) internal pure returns (uint256) {
        return amount.fromUInt().mul(scale.fromUInt()).div((10 ** 18).fromUInt()).toUInt();
    }

    function _getTrueBalance(address tokenId, address tokenId, address holder) internal view onlyTokenInitialized returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenBalanceLoaded[_msgSender()][holder]) {
            parent = parent._parent;
        }
        return parent._balances[_msgSender()][toGet] + parent._getTrueDistributionAmount(parent._privateDistributionAmount[_msgSender()], parent._privateDistribution[_msgSender()][holder]) - parent._balanceDebts[_msgSender()][toGet];
    }

    function _distributeTruePrivate(uint256 amount) internal onlyTokenInitialized {
        _privateDistributionAmount[_msgSender()] += amount;
        _totalSupply[_msgSender()] += amount;
    }

    function _distributeTrueHolders(uint256 amount) internal onlyTokenInitialized {
        _holderDistributionAmount[_msgSender()] = _holderDistributionAmount[_msgSender()].fromUInt().mul(amount.fromUInt().mul(_totalSupply[_msgSender()].fromUInt())).toUInt();
        _totalSupply[_msgSender()] += amount;
    }

    function _simplifyTrueDebts(address toSimplify) internal onlyTokenInitialized {
        if (_balances[_msgSender()][toSimplify] > _balanceDebts[_msgSender()][toSimplify]) {
            _balances[_msgSender()][toSimplify] -= balanceDebts[_msgSender()][toSimplify];
            _balanceDebts[_msgSender()][toSimplify] = 0;
        } else {
            _balanceDebts[_msgSender()][toSimplify] -= _balances[_msgSender()][toSimplify];
            _balances[_msgSender()][toSimplify] = 0;
        }
    }

    function _subtractTrueBalance(address from, uint256 amount) internal onlyTokenInitialized {
        require(_getTrueBalance(_msgSender(), from) > amount, "User doesn't have enough balance");
        
        _balanceDebts[_msgSender()][from] += amount;
        _totalSupply[_msgSender()] -= amount;
        _simplifyTrueDebts(from);
    }

    function _addTrueBalance(address to, uint256 amount) internal onlyTokenInitialized {
        _balances[_msgSender()][to] += amount;
        _totalSupply[_msgSender()] += amount;
        _simplifyTrueDebts(to);
    }

    function _transferTrue(address from, address to, uint256 amount) internal onlyTokenInitialized {
        _subtractTrueBalance(from, amount);
        _addTrueBalance(to, _getTrueDistributionAmount(amount, _transferDistribution[_msgSender()]));
        _distributeTruePrivate(_getTrueDistributionAmount(amount, _totalPrivateDistribution[_msgSender()]));
        _distributeTrueHolders(_getTrueDistributionAmount(amount, _holderDistribution[_msgSender()]));
    }

    // Helpers
    function _trueToVisible(address tokenId, uint256 amount) internal view onlyTokenInitialized returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        return parent._getTrueDistributionAmount(amount, parent._holderDistributionAmount[_msgSender()]);
    }
    
    function _visibleToTrue(address tokenId, uint256 amount) internal view onlyTokenInitialized returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        // Can't be simplified :(
        return amount.fromUInt().mul((10 ** 18).fromUInt()).div(parent._holderDistributionAmount[_msgSender()]).toUInt();
    }

    // Custom Getters for ERC20 Properties
    function totalSupply() public view onlyTokenInitialized returns (uint256) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenMetaLoaded[_msgSender()]) {
            parent = parent._parent;
        }
        return parent._trueToVisible(_msgSender(), parent._totalSupply);
    }
    
    function balanceOf(address holder) public view onlyTokenInitialized returns (uint256 balance) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenBalanceLoaded[_msgSender()][holder]) {
            parent = parent._parent;
        }
        return parent._trueToVisible(_msgSender(), parent._getTrueBalance(_msgSender(), holder));
    }
    
    function allowance(address holder, address spender) public view onlyTokenInitialized returns (uint256 remaining) {
        TokenLogicContract parent = TokenLogicContract(this);
        while (!_isWaitingOnParent && address(parent) != address(0) && !parent._tokenAllowanceLoaded[_msgSender()][holder][spender]) {
            parent = parent._parent;
        }
        return parent._allowances[_msgSender()][holder][spender];
    }
    
    // Custom Methods for ERC20 Properties
    function transfer(address sender, address to, uint256 value) public onlyUnlocked updateTokenParent updateTokenHolder(sender) updateTokenHolder(to) onlyTokenInitialized returns (bool success) {
        _transferTrue(sender, to, _visibleToTrue(_msgSender(), value));
        return true;
    }
    
    function transferFrom(address sender, address from, address to, uint256 value) public onlyUnlocked updateTokenParent updateTokenHolder(sender) updateTokenHolder(from) updateTokenHolder(to) updateTokenAllowance(sender, from) onlyTokenInitialized returns (bool success) {
        require(_allowances[_msgSender()][from][sender] >= value, "Not enough allowance");

        _allowances[_msgSender()][from][sender] -= value;
        _transferTrue(from, to, _visibleToTrue(_msgSender(), value));
        return true;
    }
    
    function approve(address sender, address spender, uint256 value) public onlyUnlocked updateTokenParent updateTokenHolder(sender) updateTokenHolder(spender) updateTokenAllowance(sender, spender) onlyTokenInitialized returns (bool success) {
        _allowances[_msgSender()][sender][spender] = value;
        return true;
    }
}
