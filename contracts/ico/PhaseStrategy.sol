

pragma solidity ^0.4.6;

/**
 * @title ICO pricing strategy class.
 * @dev The following changes have been made to TokenMarket's PricingStrategy:
 * @dev   - Removed isPresalePurchase (Rewards' presale is handled separately)
 * @dev   - Combined isPricingStrategy() and isSane() => isPhaseStrategyReady().
 * @dev   - Added responsibility for pricing start/end times and token transfers
 * @dev     (getPricingStartsAt(), getPricingEndsAt(), transfersEnabled())
 */

contract PhaseStrategy {

  /** Interface declaration. */
  function isPhaseStrategyReady() 
  public 
  view 
  returns (bool);

  /**
   * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
   *
   * @param value - What is the value of the transaction send in as wei
   * @param tokensSold - how much tokens have been sold thus far
   * @param weiRaised - how much money has been raised thus far in the main token sale
   * @param msgSender - who is the investor of this transaction
   * @param decimals - how many decimal units the token has
   * @return Amount of tokens the investor receives
   */
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint8 decimals)
  public 
  view 
  returns (uint tokenAmount);

  /**
   * @return The first second of the first phase (after which they may be sold) as a unix timestamp.
   */
  function getPricingStartsAt() 
  public 
  view 
  returns (uint);

  /**
   * @return The last second of the last phase (after which they may not be sold) 
   *         as a unix timestamp.
   */
  function getPricingEndsAt() 
  public 
  view 
  returns (uint);

  /**
   * @return Whether token transfers are locked during the current phase.
   */
  function transfersEnabled() 
  public 
  view 
  returns (bool);
}
