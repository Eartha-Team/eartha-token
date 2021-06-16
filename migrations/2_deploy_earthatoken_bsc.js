const EarthaToken = artifacts.require('EarthaToken')
const EscrowNFT = artifacts.require('EscrowNFT')
const EarthaTokenRateV2 = artifacts.require('EarthaTokenRateV2')
const EarthaTokenRateV3 = artifacts.require('EarthaTokenRateV3')

module.exports = function (deployer, network, accounts) {
  process.env.NETWORK = network

  const nftName = 'EscrowNFT'
  const nftSymbol = 'IKKI'
  const name = 'EarthaToken'
  const symbol = 'EAR'
  const cap = web3.utils.toWei('317006803', 'ether')

  let rate = EarthaTokenRateV3
  let uniswapFactoryAddress = '0x1F98431c8aD98523631AE4a59f267346ea31F984'
  let ETHAddress = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
  let USDAddress = '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419'
  let JPYAddress = '0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3'
  let EURAddress = '0xb49f677943BC038e9857d61E7d053CaA2C1734C1'
  let GBPAddress = '0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5'
  let BTCAddress = '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c'
  if (network == 'kovan') {
    ETHAddress = '0xd0a1e359811322d97991e03f863a0c30c2cf029c'
    USDAddress = '0x9326BFA02ADD2366b30bacB125260Af641031331'
    JPYAddress = '0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942'
    EURAddress = '0x0c15Ab9A0DB086e062194c273CC79f41597Bbf13'
    GBPAddress = '0x28b0061f44E6A9780224AA61BEc8C3Fcb0d37de9'
    BTCAddress = '0x6135b13325bfC4B00278B4abC5e20bbce2D6580e'
  } else if (network == 'rinkeby' || network == 'development') {
    ETHAddress = '0xc778417e063141139fce010982780140aa0cd5ab'
    USDAddress = '0x8A753747A1Fa494EC906cE90E9f37563A8AF630e'
    JPYAddress = '0x3Ae2F46a2D84e3D5590ee6Ee5116B80caF77DeCA'
    EURAddress = '0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F'
    GBPAddress = '0x7B17A813eEC55515Fb8F49F2ef51502bC54DD40F'
    BTCAddress = '0xECe365B379E1dD183B20fc5f022230C044d51404'
  } else if (network == 'bsctestnet') {
    uniswapFactoryAddress = '0xc35dadb65012ec5796536bd9864ed8773abc74c4'
    ETHAddress = '0xae13d989dac2f0debff460ac112a837c89baa7cd'
    USDAddress = '0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526'
    JPYAddress = '0x0000000000000000000000000000000000000000'
    EURAddress = '0x0000000000000000000000000000000000000000'
    GBPAddress = '0x0000000000000000000000000000000000000000'
    BTCAddress = '0x5741306c21795FdCBb9b265Ea0255F499DFe515C'
    rate = EarthaTokenRateV2
  } else if (network == 'bsc') {
    uniswapFactoryAddress = '0xc35dadb65012ec5796536bd9864ed8773abc74c4'
    ETHAddress = '0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c'
    USDAddress = '0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE'
    JPYAddress = '0x22Db8397a6E77E41471dE256a7803829fDC8bC57'
    EURAddress = '0x0bf79F617988C472DcA68ff41eFe1338955b9A80'
    GBPAddress = '0x0000000000000000000000000000000000000000'
    BTCAddress = '0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf'
    rate = EarthaTokenRateV2
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
        rate,
        18,
        USDAddress,
        JPYAddress,
        EURAddress,
        GBPAddress,
        BTCAddress,
        ETHAddress,
        earthaInstance.address,
        uniswapFactoryAddress
      )
      return earthaInstance.setRate(rateInstance.address)
    })
}
