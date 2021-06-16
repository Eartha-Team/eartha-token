const EarthaToken = artifacts.require('EarthaToken')

contract('EarthaToken', async (accounts) => {
  const NETWORK = process.env.NETWORK
  beforeEach(async () => {
    this.earthaTokenInstance = await EarthaToken.deployed()
  })
  it('should put cap value in the first account.', async () => {
    let balance = await this.earthaTokenInstance.balanceOf(accounts[0])
    let cap = await this.earthaTokenInstance.cap()
    balance = web3.utils.fromWei(balance, 'ether')
    cap = web3.utils.fromWei(cap, 'ether')

    assert.equal(balance, 700000000000, "First account don't have cap")
  })
  it('should put 100EAR in the transfer account.', async () => {
    const decimals = await this.earthaTokenInstance.decimals()
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    await this.earthaTokenInstance.transfer(accounts[1], web3.utils.toBN(100).mul(decimalPowed))

    let balance = await this.earthaTokenInstance.balanceOf(accounts[1])
    balance = web3.utils.fromWei(balance, 'ether')

    assert.equal(balance, 100, "First account don't have 100 EAR.")
  })
  it('cap error', async () => {
    try {
      const cap = await this.earthaTokenInstance.cap()
      await this.earthaTokenInstance.mint(accounts[1], web3.utils.toBN(1))
    } catch (error) {
      assert(
        error,
        'VM Exception while processing transaction: revert ERC20Capped: cap exceeded -- Reason given: ERC20Capped: cap exceeded.'
      )
    }
  })
  it('createEscrow1', async () => {
    const decimals = await this.earthaTokenInstance.decimals()
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    //now unix time
    var unix = Math.floor(new Date().getTime() / 1000) - 10

    //10EAR 200%
    await this.earthaTokenInstance.createEscrow(
      accounts[1],
      web3.utils.toBN(1000).mul(decimalPowed),
      false,
      unix,
      unix,
      'EAR',
      200
    )
  })
  it('buyerSettlement', async () => {
    await this.earthaTokenInstance.buyerSettlement(1)

    let balance0 = await this.earthaTokenInstance.balanceOf(accounts[0])
    balance0 = web3.utils.fromWei(balance0, 'ether')
    let balance1 = await this.earthaTokenInstance.balanceOf(accounts[1])
    balance1 = web3.utils.fromWei(balance1, 'ether')

    console.log(balance0)
    console.log(balance1)
  })
  it('createEscrow2', async () => {
    const decimals = await this.earthaTokenInstance.decimals()
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    //now unix time
    var unix = Math.floor(Date.now() / 1000) - 24 * 60 * 60

    //10EAR 200%
    await this.earthaTokenInstance.createEscrow(
      accounts[1],
      web3.utils.toBN(1000).mul(decimalPowed),
      false,
      unix,
      unix,
      'EAR',
      200
    )
  })
  it('sellerSettlement', async () => {
    await this.earthaTokenInstance.sellerSettlement(2, { from: accounts[1] })

    let balance0 = await this.earthaTokenInstance.balanceOf(accounts[0])
    balance0 = web3.utils.fromWei(balance0, 'ether')
    let balance1 = await this.earthaTokenInstance.balanceOf(accounts[1])
    balance1 = web3.utils.fromWei(balance1, 'ether')

    console.log(balance0)
    console.log(balance1)
  })
  it('createEscrow3', async () => {
    const decimals = await this.earthaTokenInstance.decimals()
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    //now unix time
    var unix = Math.floor(new Date().getTime() / 1000) + 100

    //10EAR 200%
    await this.earthaTokenInstance.createEscrow(
      accounts[1],
      web3.utils.toBN(1000).mul(decimalPowed),
      true,
      unix,
      unix,
      'EAR',
      200
    )
  })
  it('refund', async () => {
    await this.earthaTokenInstance.refund(3)

    let balance0 = await this.earthaTokenInstance.balanceOf(accounts[0])
    balance0 = web3.utils.fromWei(balance0, 'ether')
    let balance1 = await this.earthaTokenInstance.balanceOf(accounts[1])
    balance1 = web3.utils.fromWei(balance1, 'ether')

    console.log(balance0)
    console.log(balance1)
  })
  it('createEscrow4', async () => {
    const decimals = await this.earthaTokenInstance.decimals()
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    //now unix time
    var unix = Math.floor(new Date().getTime() / 1000) - 10

    //10EAR 200%
    await this.earthaTokenInstance.createEscrow(
      accounts[1],
      web3.utils.toBN(1000).mul(decimalPowed),
      false,
      unix,
      unix,
      'EAR',
      200
    )
  })
  it('buyerRefund Error', async () => {
    try {
      await this.earthaTokenInstance.buyerRefund(4)
    } catch (error) {
      assert(
        error,
        ' VM Exception while processing transaction: revert can not refund -- Reason given: can not refund.'
      )
    }
  })
  it('createBuyerEscrowNFT', async () => {
    await this.earthaTokenInstance.createBuyerEscrowNFT(4)
  })
})
