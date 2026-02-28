pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //
  // ------------------------------------------ //

  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _dividends;

  address[] private _holders;
  mapping(address => uint256) private _holderIndex;

  function _addHolder(address account) private {
    if (_holderIndex[account] == 0 && balanceOf[account] > 0) {
      _holders.push(account);
      _holderIndex[account] = _holders.length;
    }
  }

  function _removeHolder(address account) private {
    uint256 index = _holderIndex[account];
    if (index > 0 && balanceOf[account] == 0) {
      uint256 lastIndex = _holders.length;
      if (index != lastIndex) {
        address lastHolder = _holders[lastIndex - 1];
        _holders[index - 1] = lastHolder;
        _holderIndex[lastHolder] = index;
      }
      _holders.pop();
      _holderIndex[account] = 0;
    }
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(balanceOf[msg.sender] >= value, "Insufficient balance");

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);

    _removeHolder(msg.sender);
    _addHolder(to);

    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    _allowances[msg.sender][spender] = value;
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(balanceOf[from] >= value, "Insufficient balance");
    require(_allowances[from][msg.sender] >= value, "Insufficient allowance");

    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

    _removeHolder(from);
    _addHolder(to);

    return true;
  }

  function mint() external payable override {
    require(msg.value > 0, "No ETH sent");

    balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
    totalSupply = totalSupply.add(msg.value);

    _addHolder(msg.sender);
  }

  function burn(address payable dest) external override {
    uint256 amount = balanceOf[msg.sender];

    balanceOf[msg.sender] = 0;
    totalSupply = totalSupply.sub(amount);

    _removeHolder(msg.sender);

    dest.transfer(amount);
  }

  function getNumTokenHolders() external view override returns (uint256) {
    return _holders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    if (index == 0 || index > _holders.length) {
      return address(0);
    }
    return _holders[index - 1];
  }

  function recordDividend() external payable override {
    require(msg.value > 0, "No ETH sent");

    uint256 supply = totalSupply;
    for (uint256 i = 0; i < _holders.length; i++) {
      address holder = _holders[i];
      uint256 share = msg.value.mul(balanceOf[holder]).div(supply);
      _dividends[holder] = _dividends[holder].add(share);
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return _dividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount = _dividends[msg.sender];
    _dividends[msg.sender] = 0;
    dest.transfer(amount);
  }
}
