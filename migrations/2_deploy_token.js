let Association = artifacts.require('Association')
let CommunityVotingPool = artifacts.require('CommunityVotingPool')
let ICOFundsVault = artifacts.require('ICOFundsVault')
let Migrations = artifacts.require('Migrations')
let RewardsICOPhases = artifacts.require('RewardsICOPhases')
let RewardsICO = artifacts.require('RewardsICO')
let RewardsToken = artifacts.require('RewardsToken')
let SafeMath = artifacts.require('SafeMath')

module.exports = (deployer, network, accounts) => {
  baseUnitsFromRwrd = (rwrdAmount) => rwrdAmount * 10 ** rwrdDecimals

  const rwrdDecimals = 18
  const totalSupplyRwrd = 10 ** 9

  const initialHolders = [ICOFundsVault.address, CommunityVotingPool.address, accounts[0]]
  const initialAmountsPct = [0.3, 0.2, 0.5]

  const initialAmounts = initialAmountsPct.map(x => baseUnitsFromRwrd(totalSupplyRwrd * x))

  console.log(`Initial supply in rowans: ${baseUnitsFromRwrd(totalSupplyRwrd)}`)
  console.log(`Initial allocation: ${initialAmounts.reduce((a, b) => (a + b))}`)

  deployer.link(SafeMath, RewardsICOPhases)
  deployer.deploy(RewardsICOPhases)
  deployer.deploy([
    [RewardsToken,
      '', // name
      '', // symbol
      rwrdDecimals, // decimals
      baseUnitsFromRwrd(totalSupplyRwrd), // total supply
      initialHolders, // initial RWRD holder addresses
      initialAmounts] // base units per initial holder
  ])
}
