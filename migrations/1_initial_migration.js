let Association = artifacts.require('Association')
let CommunityVotingPool = artifacts.require('CommunityVotingPool')
let ICOFundsVault = artifacts.require('ICOFundsVault')
let Migrations = artifacts.require('Migrations')
let RewardsICOPhases = artifacts.require('RewardsICOPhases')
let RewardsICO = artifacts.require('RewardsICO')
let RewardsToken = artifacts.require('RewardsToken')
let SafeMath = artifacts.require('SafeMath')

module.exports = (deployer, network, accounts) => {
  deployer.deploy([
      Migrations,
      [ICOFundsVault,
        [accounts[0]], 1]
    ])
    deployer.deploy([
      [CommunityVotingPool,
        [accounts[0]], 1],
      SafeMath
    ])
}
