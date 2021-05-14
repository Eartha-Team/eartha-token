const EarthaTokenRate = artifacts.require("EarthaTokenRate");

contract("EarthaTokenRate", accounts => {
    const NETWORK = process.env.NETWORK;
    it("Check USDPriceFeedAddress", async () => {
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const USDPriceFeed = await earthaTokenRateInstance.USDPriceFeed();
        const USDPriceFeedAddress = USDPriceFeed;
        if (NETWORK == "development") {
            assert.equal(USDPriceFeedAddress, '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', "USDPriceFeedAddress is not 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419");
        } else if (NETWORK == "kovan") {
            assert.equal(USDPriceFeedAddress, '0x9326BFA02ADD2366b30bacB125260Af641031331', "USDPriceFeedAddress is not 0x9326BFA02ADD2366b30bacB125260Af641031331");
        } else {
            assert.equal(USDPriceFeedAddress, '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', "USDPriceFeedAddress is not 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419");
        }
    });
    it("Check JPYPriceFeedAddress", async () => {
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const JPYPriceFeedAddress = await earthaTokenRateInstance.rateFeeds('JPY');

        if (NETWORK == "development") {
            assert.equal(JPYPriceFeedAddress, '0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3', "JPYPriceFeedAddress is not 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3");
        } else if (NETWORK == "kovan") {
            assert.equal(JPYPriceFeedAddress, '0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942', "JPYPriceFeedAddress is not 0xD627B1eF3AC23F1d3e576FA6206126F3c1Bd0942");
        } else {
            assert.equal(JPYPriceFeedAddress, '0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3', "JPYPriceFeedAddress is not 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3");
        }
    });
    it("Check getXTo EAR", async () => {
        const decimals = web3.utils.toBN(18);
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const result = await earthaTokenRateInstance.getXTo(web3.utils.toBN(1).mul(decimalPowed), 'EAR');
        console.log(result.toString())
    });
    it("Check getXTo USD", async () => {
        const decimals = web3.utils.toBN(18);
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const result = await earthaTokenRateInstance.getXTo(web3.utils.toBN(1).mul(decimalPowed), 'USD');
        console.log(result.toString())
    });
    it("Check getXTo JPY", async () => {
        const decimals = web3.utils.toBN(18);
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const result = await earthaTokenRateInstance.getXTo(web3.utils.toBN(1).mul(decimalPowed), 'JPY');

        console.log(result.toString())
    });
    it("Check getToX EAR", async () => {
        const decimals = web3.utils.toBN(18);
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const result = await earthaTokenRateInstance.getToX(web3.utils.toBN(1).mul(decimalPowed), 'EAR');

        console.log(result.toString())
    });
    it("Check getToX USD", async () => {
        const decimals = web3.utils.toBN(18);
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const result = await earthaTokenRateInstance.getToX(web3.utils.toBN(1).mul(decimalPowed), 'USD');

        console.log(result.toString())
    });
    it("Check getToX JPY", async () => {
        const decimals = web3.utils.toBN(18);
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        const earthaTokenRateInstance = await EarthaTokenRate.deployed();
        const result = await earthaTokenRateInstance.getToX(web3.utils.toBN(1).mul(decimalPowed), 'JPY');

        console.log(result.toString())
    });
});