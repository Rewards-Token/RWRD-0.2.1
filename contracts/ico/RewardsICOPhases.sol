pragma solidity ^0.4.16;

/**
 * @title Phase strategy implementation for Rewards' ICO.
 */

import '../ico/PhaseStrategy.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract RewardsICOPhases is PhaseStrategy, Ownable {

  using SafeMath for uint;

  event RewardsICOPhasesInitialized();

  // This contains all pre-ICO addresses, and their prices (weis per token)
  mapping (address => uint) public preicoAddresses;

  struct Phase {
    uint256 time; // Time phase comes into effect (unix timestamp)
    uint256 price; // Price during phase
    bool transfersEnabled; // Whether or not tokens are locked during phase
  }

  Phase[] public phases;

  // How many active phases we have
  uint public phaseCount;

  bool public isInitialized;

  function RewardsICOPhases() {
    // ...
  }

  /**
   * @dev Set up the phases. 
   * @dev This functionality used to be in the constructor, but constructors in Solidity cannot be external.
   * @dev Making this functionality external may save 50% on gas: see
   * @dev https://ethereum.stackexchange.com/questions/19380/external-vs-public-best-practices
   *
   * @dev This function may only be called by the owner, and may only be called once (successfully.)
   */
  function initialize(uint256[] _times, uint256[] _prices, bool[] _transfersEnabled) 
  external 
  onlyOwner {
    require( ! isInitialized);
    
    // All input arrays must be the same length.
    require(_times.length == _prices.length);
    require(_prices.length == _transfersEnabled.length);

    // Last phase's price must be zero, terminating the ICO.
    require(_prices[_prices.length - 1] == 0);

    phaseCount = _times.length;

    for (uint8 i = 0; i < phaseCount; i++) {
      // Times of phases must be strictly increasing.
      if (i > 0) {
        require(_times[i] > _times[i - 1]);
      }
      Phase memory newPhase = Phase({time: _times[i], price: _prices[i], transfersEnabled: _transfersEnabled[i]});
      phases.push(newPhase);
    }

    isInitialized = true;
    RewardsICOPhasesInitialized();
  }

  // ! PhaseStrategy interface functions

  function isPhaseStrategyReady() 
  public 
  view 
  returns (bool) {
    return isInitialized;
  }

  /// @dev Calculate the current price for buy in amount.
  function calculatePrice(uint value, uint /*weiRaised*/, uint /*tokensSold*/, address msgSender, uint8 decimals) 
  public 
  view 
  returns (uint) {
    uint256 multiplier = 10 ** uint256(decimals);
    uint256 price = getCurrentPrice();

    return value.mul(multiplier).div(price);
  }

  function getPricingStartsAt() 
  public 
  view 
  returns (uint) {
    return phases[0].time;
  }

  function getPricingEndsAt() 
  public 
  view 
  returns (uint) {
    return phases[phaseCount - 1].time;
  }

  function transfersEnabled() 
  public 
  view 
  returns (bool) {
    uint256 phaseNum;
    Phase memory currentPhase;
    (phaseNum, currentPhase) = getCurrentPhase();
    if (phaseNum == phases.length) {
      return true;
    }
    else {
      return currentPhase.transfersEnabled;
    }
  }

  // ! End PhaseStrategy interface functions

  /// @dev Internal function for finding the current phase.
  /// @return double: uint256 phaseNum (the index of the current phase plus one, 
  ///                                   or == phases.length if ICO is over),
  ///                 Phase currentPhase
  function getCurrentPhase() 
  internal
  view
  returns (uint256 i, Phase currentPhase) {
    for (i = 1; i < phases.length; i++) {
      if (now < phases[i].time) {
      return (i, phases[i - 1]);
      }
    }
    Phase memory zeroPhase;
    return (i, zeroPhase);
  }

  /// @dev Get the current price.
  /// @return The current price or 0 if ICO is complete
  function getCurrentPrice() 
  public 
  view 
  returns (uint result) {
    uint256 phaseNum;
    Phase memory currentPhase;
    (phaseNum, currentPhase) = getCurrentPhase();
    if (phaseNum == phases.length) {
      return 0;
    }
    else {
      return currentPhase.price;
    }
  }

  function getCurrentPhaseNumber()
  public
  view
  returns (uint256 result) {
    uint256 phaseNum;
    Phase memory currentPhase;
    (phaseNum, currentPhase) = getCurrentPhase();
    return phaseNum;
  }
}
