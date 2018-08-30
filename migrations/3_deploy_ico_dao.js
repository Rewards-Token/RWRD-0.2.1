let Association = artifacts.require('Association')
let CommunityVotingPool = artifacts.require('CommunityVotingPool')
let ICOFundsVault = artifacts.require('ICOFundsVault')
let Migrations = artifacts.require('Migrations')
let RewardsICOPhases = artifacts.require('RewardsICOPhases')
let RewardsICO = artifacts.require('RewardsICO')
let RewardsToken = artifacts.require('RewardsToken')
let SafeMath = artifacts.require('SafeMath')

module.exports = async (deployer, network, accounts) => {
  const secondsInWeek = 604800
  const secondsInMonth = 2592000

  const now = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1
  const icoTimes = [now, now + secondsInWeek, now + secondsInMonth],
    icoPrices = [web3.toWei('0.25', 'ether'), web3.toWei('0.5', 'ether'), 0],
    icoTransfersEnabled = [true, false, true]

  deployer.then(() => {
    return RewardsICOPhases.deployed()
  }).then((_phaseStrategy) => {
    _phaseStrategy.initialize(icoTimes, icoPrices, icoTransfersEnabled)
  })
  deployer.deploy([
    [Association,
      RewardsToken.address],
    [RewardsICO,
      ICOFundsVault.address,
      RewardsToken.address,
      accounts[1], // Verifier address
      RewardsICOPhases.address]
  ])
}
