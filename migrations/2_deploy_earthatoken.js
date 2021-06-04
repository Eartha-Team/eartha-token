const EarthaToken = artifacts.require('EarthaToken')
const EscrowNFT = artifacts.require('EscrowNFT')
const EarthaTokenRate = artifacts.require('EarthaTokenRate')

module.exports = function (deployer, network, accounts) {
  process.env.NETWORK = network

  const now = Date.now()
  const nftName = 'EscrowNFT' + now
  const nftSymbol = 'IKKI'
  const name = 'EarthaToken' + now
  const symbol = 'EAR'
  const capDecimals = web3.utils.toBN(18 + 12)
  const capDecimalPowed = web3.utils.toBN(10).pow(capDecimals)
  const cap = web3.utils.toBN(1).mul(capDecimalPowed)
  let uniswapFactoryAddress = '0x1F98431c8aD98523631AE4a59f267346ea31F984'
  let ETHAddress = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
  let USDAddress = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419'
  let JPYAddress = '0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3'
  let EURAddress = '0xb49f677943BC038e9857d61E7d053CaA2C1734C1'
  let GBPAddress = '0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5'
  if (network == 'kovan') {
    ETHAddress = '0xd0a1e359811322d97991e03f863a0c30c2cf029c'
    USDAddress = '0x9326BFA02ADD2366b30bacB125260Af641031331'
    JPYAddress = '0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942'
    EURAddress = '0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13'
    GBPAddress = '0x28b0061f44E6A9780224AA61BEc8C3Fcb0d37de9'
  } else if (network == 'rinkeby') {
    ETHAddress = '0xc778417e063141139fce010982780140aa0cd5ab'
    USDAddress = '0x8A753747A1Fa494EC906cE90E9f37563A8AF630e'
    JPYAddress = '0x3Ae2F46a2D84e3D5590ee6Ee5116B80caF77DeCA'
    EURAddress = '0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F'
    GBPAddress = '0x7B17A813eEC55515Fb8F49F2ef51502bC54DD40F'
  }

  return deployer
    .then(() => {
      return deployer.deploy(EscrowNFT, nftName, nftSymbol)
    })
    .then(async (instance) => {
      const earthaInstance = await deployer.deploy(EarthaToken, name, symbol, cap, instance.address)
      instance.grantRole(await instance.MINTER_ROLE(), earthaInstance.address)
      return earthaInstance
    })
    .then(async (earthaInstance) => {
      const rateInstance = await deployer.deploy(
        EarthaTokenRate,
        18,
        USDAddress,
        JPYAddress,
        EURAddress,
        GBPAddress,
        ETHAddress,
        earthaInstance.address,
        uniswapFactoryAddress
      )
      return earthaInstance.initializeTokenRate(rateInstance.address)
    })
}
