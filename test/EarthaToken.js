const EarthaToken = artifacts.require("EarthaToken");

contract("EarthaToken", async accounts => {
    const NETWORK = process.env.NETWORK;
    beforeEach(async () => {
        this.earthaTokenInstance = await EarthaToken.deployed();
    })
    it("should put cap value in the first account.", async () => {
        let balance = await this.earthaTokenInstance.balanceOf(accounts[0]);
        let cap = await this.earthaTokenInstance.cap();
        balance = web3.utils.fromWei(balance, "ether");
        cap = web3.utils.fromWei(cap, "ether");

        assert.equal(balance, 700000000000, "First account don't have cap");
    });
    it("should put 100EAR in the transfer account.", async () => {
        const decimals = await this.earthaTokenInstance.decimals();
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        await this.earthaTokenInstance.transfer(accounts[1], web3.utils.toBN(100).mul(decimalPowed));

        let balance = await this.earthaTokenInstance.balanceOf(accounts[1]);
        balance = web3.utils.fromWei(balance, "ether");

        assert.equal(balance, 100, "First account don't have 100 EAR.");
    });
    it("cap error", async () => {
        try {
            const cap = await this.earthaTokenInstance.cap();
            await this.earthaTokenInstance.mint(accounts[1], web3.utils.toBN(1));
        } catch (error) {
            assert(error, "VM Exception while processing transaction: revert ERC20Capped: cap exceeded -- Reason given: ERC20Capped: cap exceeded.");
        }
    });
    it("createEscrow1", async () => {
        const decimals = await this.earthaTokenInstance.decimals();
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        //now unix time
        var unix = Math.floor(new Date().getTime()/1000)-10;

        //10EAR 200%
        await this.earthaTokenInstance.createEscrow(accounts[1], web3.utils.toBN(1000).mul(decimalPowed), false, unix, 'EAR', 200);
    });
    it("completeEscrow", async () => {
        await this.earthaTokenInstance.completeEscrow(1);

        let balance0 = await this.earthaTokenInstance.balanceOf(accounts[0]);
        balance0 = web3.utils.fromWei(balance0, "ether");
        let balance1 = await this.earthaTokenInstance.balanceOf(accounts[1]);
        balance1 = web3.utils.fromWei(balance1, "ether");

        assert.equal(balance0, 699999999800, "First account don't have 699999999800 EAR.");
        assert.equal(balance1, 2000, "First account don't have 2000 EAR.");
    });
    it("createEscrow2", async () => {
        const decimals = await this.earthaTokenInstance.decimals();
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        //now unix time
        var unix = Math.floor(Date.now() / 1000) - 24 * 60 * 60;

        //10EAR 200%
        await this.earthaTokenInstance.createEscrow(accounts[1], web3.utils.toBN(1000).mul(decimalPowed), false, unix, 'EAR', 200);
    });
    it("terminateEscrow", async () => {
        await this.earthaTokenInstance.terminateEscrow(2, {from:accounts[1]});

        let balance0 = await this.earthaTokenInstance.balanceOf(accounts[0]);
        balance0 = web3.utils.fromWei(balance0, "ether");
        let balance1 = await this.earthaTokenInstance.balanceOf(accounts[1]);
        balance1 = web3.utils.fromWei(balance1, "ether");

        assert.equal(balance0, 699999999700, "First account don't have 699999999700 EAR.");
        assert.equal(balance1, 3900, "First account don't have 3900 EAR.");
    });
    it("createEscrow3", async () => {
        const decimals = await this.earthaTokenInstance.decimals();
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        //now unix time
        var unix = Math.floor(new Date().getTime() / 1000) - 10;

        //10EAR 200%
        await this.earthaTokenInstance.createEscrow(accounts[1], web3.utils.toBN(1000).mul(decimalPowed), true, unix, 'EAR', 200);
    });
    it("refundEscrow", async () => {
        await this.earthaTokenInstance.refundEscrow(3);

        let balance0 = await this.earthaTokenInstance.balanceOf(accounts[0]);
        balance0 = web3.utils.fromWei(balance0, "ether");
        let balance1 = await this.earthaTokenInstance.balanceOf(accounts[1]);
        balance1 = web3.utils.fromWei(balance1, "ether");

        assert.equal(balance0, 699999999700, "First account don't have 699999999700 EAR.");
        assert.equal(balance1, 3900, "First account don't have 3900 EAR.");
    });
    it("createEscrow4", async () => {
        const decimals = await this.earthaTokenInstance.decimals();
        const decimalPowed = web3.utils.toBN(10).pow(decimals);
        //now unix time
        var unix = Math.floor(new Date().getTime() / 1000) - 10;

        //10EAR 200%
        await this.earthaTokenInstance.createEscrow(accounts[1], web3.utils.toBN(1000).mul(decimalPowed), false, unix, 'EAR', 200);
    });
    it("refundEscrow Error", async () => {
        try {
            await this.earthaTokenInstance.refundEscrow(4);
        } catch (error) {
            assert(error, " VM Exception while processing transaction: revert can not refund -- Reason given: can not refund.");
        }
    });
    it("createEscrowCreaterNFT", async () => {
        await this.earthaTokenInstance.createEscrowCreaterNFT(4);
    });
});