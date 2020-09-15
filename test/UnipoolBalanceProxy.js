const { BN, expectRevert } = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const UniswapToken = artifacts.require('UniswapTokenMock');
const TradedToken = artifacts.require('HoneyTokenMock');
const Unipool = artifacts.require('UnipoolMock');
const UnipoolBalanceProxy = artifacts.require('UnipoolBalanceProxyMock');

contract('UnipoolFactory', function ([_, wallet1, wallet2, wallet3, wallet4]) {
    describe('UnipoolFactory', async function () {
        beforeEach(async function () {
            this.uniswapToken = await UniswapToken.new();
            this.tradedToken = await TradedToken.new(wallet1);
            this.pool = await Unipool.new(this.uniswapToken.address, this.tradedToken.address);
            this.proxy = await UnipoolBalanceProxy.new(this.pool.address, this.tradedToken.address);

            await this.tradedToken.mint(wallet1, web3.utils.toWei('1000'));
            await this.tradedToken.transfer(this.proxy.address, web3.utils.toWei('1000'), { from: wallet1 });
        });

        it('transfers its balances to the pool', async function () {
            await this.proxy.transfer()
            expect(await this.tradedToken.balanceOf(this.pool.address)).to.be.bignumber.equal(web3.utils.toWei('1000'));
            expect(await this.tradedToken.balanceOf(this.proxy.address)).to.be.bignumber.equal('0');
        });
    });
});
