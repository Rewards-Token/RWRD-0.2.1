let Association = artifacts.require('Association')
let CommunityVotingPool = artifacts.require('CommunityVotingPool')
let ICOFundsVault = artifacts.require('ICOFundsVault')
let Migrations = artifacts.require('Migrations')
let RewardsICO = artifacts.require('RewardsICO')
let RewardsToken = artifacts.require('RewardsToken')

const associationInitialBalance = 2 * 10 ** (8 + 18)

module.exports = async (deployer, network, accounts) => {
  /**
   * Return a Promise which, when awaited, will cause `walletContract`
   * to approve the execution of `method` with `args` from each of the `senders`.
   * Note: do not depend on the transaction being unexecuted until you await this promise.
   * The transaction will execute before this method returns if only one confirmation is
   * needed.
   *
   * Example call:
   * await multiSigWalletExecute(myMSW,
   *                 richContract,
   *                 'cashOutFunc',
   *                 [arg1, arg2, ...],
   *                 web3.toWei('1', 'ether'),
   *                 web3.eth.accounts)
   */
  multiSigWalletExecute = async (walletContract, destContract, method, args, value, senders) => {
    if (!Array.isArray(senders)) {
      throw new Error('"senders" must be an array of unlocked addresses')
    }
    const [firstSender, ...otherSenders] = senders
    if (!firstSender) {
      throw new Error('"senders" array must not be empty')
    }
    const txData = destContract[method].request(...args).params[0].data
    await walletContract.submitTransaction(destContract.address, value, txData, {from: firstSender})
    const txCount = await walletContract.transactionCount.call()
    const txId = txCount - 1
    await Promise.all(otherSenders.map((senderAddress) => {
      walletContract.confirmTransaction(txId, {from: senderAddress})
    }))
  }

  getSolidityArray = async (arrayMethod) => {
    let result = []
    for (let i = 0; ; i++) {
      try {
        result.push(await arrayMethod.call(i))
      } catch (e) {
        return result
      }
    }
  }

  deployer.then(() => {
    console.log('Retrieving contracts...')
    return Promise.all([Association.deployed(), RewardsICO.deployed(), RewardsToken.deployed(), CommunityVotingPool.deployed()])
  }).then((contracts) => {
    [association, ico, token, cvp] = contracts
  }).then(() => {
    console.log('Disabling token transfers...')
    return ico.allowTokenTransfers(false, {from: accounts[0]})
  }).then(() => {
    console.log('Setting CommunityVotingPool token contract...')
    return multiSigWalletExecute(cvp, cvp, 'setTokenContract', [token.address], 0, [accounts[0]])
  }).then(() => {
    console.log('Adding DAO as owner of CommunityVotingPool...')
    return multiSigWalletExecute(cvp, cvp, 'addOwner', [association.address], 0, [accounts[0]])
  }).then(() => {
    console.log('Setting CommunityVotingPool minimum requirements to (2)...')
    return multiSigWalletExecute(cvp, cvp, 'changeRequirement', [new web3.BigNumber(2)], 0, [accounts[0]])
  }).then(() => {
    console.log('Setting association MSW to deployed CommunityVotingPool...')
    return association.setCommunityVotingPool(CommunityVotingPool.address)
  })
}
