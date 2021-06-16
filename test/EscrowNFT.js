const EscrowNFT = artifacts.require('EscrowNFT')

contract('EscrowNFT', function (/* accounts */) {
  beforeEach(async () => {
    this.escrowMFTInstance = await EscrowNFT.deployed()
  })
  it('call totalSupply', async () => {
    const totalSupply = await this.escrowMFTInstance.totalSupply()
    assert.equal(totalSupply, 0, "Total supply isn't 0")
  })
})
