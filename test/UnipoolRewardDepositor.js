const { BN, expectRevert } = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const UniswapToken = artifacts.require('UniswapTokenMock');
const RewardToken = artifacts.require('HoneyTokenMock');
const Unipool = artifacts.require('UnipoolMock');
const UnipoolRewardDepositor = artifacts.require('UnipoolBalanceProxyMock');

contract('UnipoolRewardDepositor', function ([_, wallet1, wallet2, wallet3, wallet4]) {
    describe('UnipoolRewardDepositor', async function () {
        beforeEach(async function () {
            this.uniswapToken = await UniswapToken.new();
            this.rewardToken = await RewardToken.new(wallet1);
            this.pool = await Unipool.new(this.uniswapToken.address, this.rewardToken.address);
            this.proxy = await UnipoolRewardDepositor.new(this.pool.address, this.rewardToken.address);

            await this.rewardToken.mint(wallet1, web3.utils.toWei('1000'));
            await this.rewardToken.transfer(this.proxy.address, web3.utils.toWei('1000'), { from: wallet1 });
        });

        it('transfers its balances to the pool', async function () {
            await this.proxy.transfer()
            expect(await this.rewardToken.balanceOf(this.pool.address)).to.be.bignumber.equal(web3.utils.toWei('1000'));
            expect(await this.rewardToken.balanceOf(this.proxy.address)).to.be.bignumber.equal('0');
        });
    });
});
