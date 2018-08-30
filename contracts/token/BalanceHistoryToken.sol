
pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract BalanceHistoryToken is StandardToken {

  event BalanceChanged(address who, uint256 newBalance, uint256 blockNum);

  using SafeMath for uint256;

  struct BalanceRecord {
    uint256 blockNum;
    uint256 balance;
  }

  uint256 public totalSupply;

  mapping (address => BalanceRecord[]) balancesAt;

  /**
   * @notice Find an address' "current balance" at a certain block.
   *
   * @dev A balance history for an address is stored as an array of tuples (balance, blockNum)
   * for each blockNum at which the balance changed. If there are multiple transactions in one block
   * that change an address' balance, however, only the most recent balance is stored: there are no
   * duplicate blockNums. Each tuple is added to the end of the balance history forming a
   * monotonically increasing sequence.
   *      An address' "current" balance with respect to a block number N is the balance associated with
   * the maximum value of blockNum not greater than N, or zero if there is no such value.
   *
   * @param _owner Address whose balance is returned
   * @param blockNum Block number
   * @return _owner's current balance w.r.t. blockNum
   */
  function balanceOfAt(address _owner, uint256 blockNum)
  public
  view
  returns (uint256) {
    BalanceRecord[] storage records = balancesAt[_owner];
    if (records.length == 0) {
      return 0;
    }
    if (records[0].blockNum > blockNum) {
      return 0;
    }

    // It is always true that:
    // 1. Elements before low are strictly LT blockNum.
    // 2. Elements after high are strictly GT blockNum.
    uint256 low = 0;
    uint256 high = records.length.sub(1);

    while (low <= high) {
      uint256 mid = (low.add(high)).div(2);
      uint256 midBlockNum = records[mid].blockNum;
      if (midBlockNum < blockNum) {
        low = mid.add(1);
      }
      else { if (midBlockNum > blockNum) {
        high = mid.sub(1);
      }
      else {
        // Exact match.
        return records[mid].balance;
      } }
    }
    // No exact match--want to return last value strictly LT blockNum.
    // The minimum possible value for mid = floor(low+high/2) [given no negative numbers, overflows, low<=high] is low.
    // Hence high == low - 1.
    // We know all items less than low are strictly LT the target. High is the last such element. 
    assert(high == low - 1);
    return records[high].balance;
  }

  function balanceOf(address _owner)
  public
  view
  returns (uint256) {
    BalanceRecord[] storage records = balancesAt[_owner];
    if (records.length == 0) {
      return 0;
    }
    return records[records.length.sub(1)].balance;
  }

  function pushBalance(address _owner, uint256 _balance)
  internal {
    BalanceRecord memory newRecord = BalanceRecord({blockNum: block.number, balance: _balance});
    balancesAt[_owner].push(newRecord);
  }

  function setBalanceOf(address _owner, uint256 _balance)
  internal {
    BalanceRecord[] storage records = balancesAt[_owner];
    if (records.length == 0) {
      pushBalance(_owner, _balance);
    }
    else {
      BalanceRecord storage oldRecord = records[records.length.sub(1)];
      assert(block.number >= oldRecord.blockNum);
      if (oldRecord.blockNum == block.number) {
        oldRecord.balance = _balance;
      }
      else {
        pushBalance(_owner, _balance);
      }
    }
    BalanceChanged(_owner, _balance, block.number);
  }

  /*
   * transferFrom() and transfer() are taken from OpenZeppelin's StandardToken.sol
   * and BasicToken.sol, respectively. The only change was replacement of 
   * balances[address] with setBalanceOf() and balanceOf().
   */
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) 
  public 
  returns (bool) {
  require(_to != address(0));

  uint256 _allowance = allowed[_from][msg.sender];

  // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
  // require (_value <= _allowance);

  setBalanceOf(_from, balanceOf(_from).sub(_value));
  setBalanceOf(_to, balanceOf(_to).add(_value));
  allowed[_from][msg.sender] = _allowance.sub(_value);
  Transfer(_from, _to, _value);
  return true;
  }

  function transfer(address _to, uint256 _value) 
  public 
  returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_value));
    setBalanceOf(_to, balanceOf(_to).add(_value));

    Transfer(msg.sender, _to, _value);
    return true;
  }
}