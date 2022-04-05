// SPDX-License-Identifier: MIT
// Made with https://github.com/Pandapip1/CustomTokens
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/abdk-consulting/abdk-libraries-solidity/blob/v3.0/ABDKMathQuad.sol";
import "./ERC20Proxied.sol";

contract TokenLogicContract is Multicall, Ownable, ERC2771Context {
    // Libraries
    using SafeCast for *;
    using ABDKMathQuad for *;

    // Version number: Used for upgrades
    uint256 public constant _version = 0;
    
    // Token Config: Meta
    mapping(address => string) public _name;
    mapping(address => string) public _symbol;
    
    // Token Config: Dist
    mapping(address => mapping(address => uint256)) public _privateDistribution;
    mapping(address => uint256) public _totalPrivateDistribution = 0;
    mapping(address => uint256) public _holderDistribution = 0;
    mapping(address => uint256) public _transferDistribution = 0;

    // Token State: Balances
    mapping(address => mapping(address => uint256)) public _balances;
    mapping(address => mapping(address => uint256)) public _balanceDebts;
    mapping(address => uint256) public _holderDistributionAmount = 10**18; // Amount to multiply final balances by
    mapping(address => uint256) public _privateDistributionAmount = 0; // Amount to add to balances

    // Token State: Allowances
    mapping(address => mapping(address => mapping(address => uint256))) public _allowances; // More standard ERC20 stuff
    
    // Token State: Total Supply
    mapping(address => uint256) public _totalSupply = 0;
    
    // Token Creation
    mapping(address => address) public _owners;
    mapping(address => address) public _reverseOwners;
    
    // Logic Upgradeability
    bool public _hasParent;
    bool public _isWaitingOnParent;
    TokenLogicContract public _parent;
    bool public _isFrozen;
    
    // Lazy Upgrade Information
    mapping(address => bool) _ownerLoaded;
    mapping(address => bool) _tokenMetaLoaded;
    mapping(address => mapping(address => bool)) _tokenBalanceLoaded;
    mapping(address => mapping(address => mapping(address => bool))) _tokenAllowanceLoaded;

    // Modifiers
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

    modifier tokenInit {
        TokenLogicContract parent = _getOwnerParent(tokenOwner);
        // Make token if one isn't currently being made
        if (parent._reverseOwners[_msgSender()] == address(0)) {
            ERC20Proxied newToken = new ERC20Proxied(); // TODO arguments
            _doesTokenExist[address(newToken)] = true;
            _owners[address(newToken)] = _msgSender();
            _reverseOwners[_msgSender()] = address(newToken);
        }
        _;
    }

    modifier tokenLive(address token) {
        TokenLogicContract parent = _getTokenParent(token);
        require(parent._owner[token] == address(0));
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

    // Upgrade Helpers
    function _getOwnerParent(address tokenOwner) internal view returns (TokenLogicContract) {
        if (_ownerLoaded[tokenOwner]) {
            return TokenLogicContract(this);
        }
        if (_hasParent) {
            return _parent._getOwnerParent(tokenOwner);
        }
        return TokenLogicContract(this);
    }

    function _getTokenParent(address token) internal view returns (TokenLogicContract) {
        if (_tokenMetaLoaded[token]) {
            return TokenLogicContract(this);
        }
        if (_hasParent) {
            return _parent._getTokenParent(token);
        }
        return TokenLogicContract(this);
    }

    function _getHolderParent(address token, address holder) internal view returns (TokenLogicContract) {
        if (_tokenBalanceLoaded[token][holder]) {
            return TokenLogicContract(this);
        }
        if (_hasParent) {
            return _parent._getHolderParent(token, holder);
        }
        return TokenLogicContract(this);
    }

    function _getAllowanceParent(address token, address holder, address sender) internal view returns (TokenLogicContract) {
        if (_tokenAllowanceLoaded[token][holder][sender]) {
            return TokenLogicContract(this);
        }
        if (_hasParent) {
            return _parent._getAllowanceParent(token, holder, sender);
        }
        return TokenLogicContract(this);
    }

    function _loadOwner(address tokenOwner) internal {
        TokenLogicContract parent = _getOwnerParent(tokenOwner);

        _reverseOwners[tokenOwner] = parent._reverseOwners[tokenOwner];

        _ownerLoaded[tokenOwner] = true;
    }

    function _loadToken(address token) internal {
        TokenLogicContract parent = _getTokenParent(token);

        _name[token] = parent._name[token];
        _symbol[token] = parent._symbol[token];
        _owners[token] = parent._owners[token];
        _doesTokenExist[token] = parent._doesTokenExist[token];
        _totalPrivateDistribution[token] = parent._totalPrivateDistribution[token];
        _holderDistribution[token] = parent._holderDistribution[token];
        _transferDistribution[token] = parent._transferDistribution[token];
        _totalSupply[token] = parent._totalSupply[token];
        _holderDistributionAmount[token] = parent._holderDistributionAmount[token];
        _privateDistributionAmount[token] = parent._privateDistributionAmount[token];

        _tokenMetaLoaded[token] = true;
    }

    function _loadHolder(address token, address holder) internal {
        TokenLogicContract parent = _getHolderParent(token, holder);

        _balances[token][holder] = parent._balances[token][holder];
        _balanceDebts[token][holder] = parent._balanceDebts[token][holder];
        _privateDistribution[token][holder] = parent._privateDistribution[token][holder];
        
        _tokenBalanceLoaded[token][holder] = true;
    }

    function _loadAllowance(address token, address holder, address sender) internal {
        TokenLogicContract parent = _getAllowanceParent(token, holder, sender);

        _allowances[token][holder][sender] = parent._allowances[token][holder][sender];

        _tokenBalanceLoaded[token][holder][sender] = true;
    }

    // Upgradeability
    function freeze() public onlyOwner {
        _isFrozen = true;
    }
    
    // Initialization Functions
    function setName(string memory newName) public onlyInit {
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
