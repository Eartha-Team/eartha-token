const EarthaTokenRateV2 = artifacts.require('EarthaTokenRateV2')

contract('EarthaTokenRateV2', (accounts) => {
  const NETWORK = process.env.NETWORK
  it('Check USDPriceFeedAddress', async () => {
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const USDPriceFeed = await earthaTokenRateInstance.USDPriceFeed()
    const USDPriceFeedAddress = USDPriceFeed
    if (NETWORK == 'rinkeby' || NETWORK == 'development') {
      assert.equal(
        USDPriceFeedAddress,
        '0x8A753747A1Fa494EC906cE90E9f37563A8AF630e',
        'USDPriceFeedAddress is not 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e'
      )
    } else if (NETWORK == 'kovan') {
      assert.equal(
        USDPriceFeedAddress,
        '0x9326BFA02ADD2366b30bacB125260Af641031331',
        'USDPriceFeedAddress is not 0x9326BFA02ADD2366b30bacB125260Af641031331'
      )
    } else {
      assert.equal(
        USDPriceFeedAddress,
        '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
        'USDPriceFeedAddress is not 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419'
      )
    }
  })
  it('Check JPYPriceFeedAddress', async () => {
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const JPYPriceFeedAddress = await earthaTokenRateInstance.rateFeeds('JPY')

    if (NETWORK == 'rinkeby' || NETWORK == 'development') {
      assert.equal(
        JPYPriceFeedAddress,
        '0x3Ae2F46a2D84e3D5590ee6Ee5116B80caF77DeCA',
        'JPYPriceFeedAddress is not 0x3Ae2F46a2D84e3D5590ee6Ee5116B80caF77DeCA'
      )
    } else if (NETWORK == 'kovan') {
      assert.equal(
        JPYPriceFeedAddress,
        '0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942',
        'JPYPriceFeedAddress is not 0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942'
      )
    } else {
      assert.equal(
        JPYPriceFeedAddress,
        '0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3',
        'JPYPriceFeedAddress is not 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3'
      )
    }
  })
  it('Check getXTo EAR', async () => {
    const decimals = web3.utils.toBN(18)
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const result = await earthaTokenRateInstance.getXTo(web3.utils.toBN(1).mul(decimalPowed), 'EAR')

    assert.equal(result.toString(), web3.utils.toBN(1).mul(decimalPowed).toString(), 'Not 1EAR')
  })
  it('Check getXTo USD', async () => {
    const decimals = web3.utils.toBN(18)
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const result = await earthaTokenRateInstance.getXTo(web3.utils.toBN(1).mul(decimalPowed), 'USD')

    console.log(result.toString())
  })
  it('Check getXTo JPY', async () => {
    const decimals = web3.utils.toBN(18)
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const result = await earthaTokenRateInstance.getXTo(web3.utils.toBN(1).mul(decimalPowed), 'JPY')

    console.log(result.toString())
  })
  it('Check getToX EAR', async () => {
    const decimals = web3.utils.toBN(18)
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const result = await earthaTokenRateInstance.getToX(web3.utils.toBN(1).mul(decimalPowed), 'EAR')

    assert.equal(result.toString(), web3.utils.toBN(1).mul(decimalPowed).toString(), 'Not 1EAR')
  })
  it('Check getToX USD', async () => {
    const decimals = web3.utils.toBN(18)
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const result = await earthaTokenRateInstance.getToX(web3.utils.toBN(1).mul(decimalPowed), 'USD')

    console.log(result.toString())
  })
  it('Check getToX JPY', async () => {
    const decimals = web3.utils.toBN(18)
    const decimalPowed = web3.utils.toBN(10).pow(decimals)
    const earthaTokenRateInstance = await EarthaTokenRateV2.deployed()
    const result = await earthaTokenRateInstance.getToX(web3.utils.toBN(1).mul(decimalPowed), 'JPY')

    console.log(result.toString())
  })
})
