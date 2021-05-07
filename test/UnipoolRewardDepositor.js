const { expect } = require('chai');

const Token = artifacts.require('Token');
const Unipool = artifacts.require('Unipool');
const UnipoolRewardDepositor = artifacts.require('UnipoolRewardDepositor');

contract('UnipoolRewardDepositor', function ([_, wallet1, wallet2, wallet3, wallet4]) {
    describe('UnipoolRewardDepositor', async function () {
        beforeEach(async function () {
            this.rewardToken = await Token.new();
            this.unipool = await Unipool.new(this.rewardToken.address);
            this.unipoolRewardDepositor = await UnipoolRewardDepositor.new(this.unipool.address, this.rewardToken.address);

            await this.rewardToken.mint(wallet1, web3.utils.toWei('1000'));
            await this.rewardToken.transfer(this.unipoolRewardDepositor.address, web3.utils.toWei('1000'), { from: wallet1 });
        });

        it('transfers its balances to the pool', async function () {
            await this.unipoolRewardDepositor.transfer()
            expect(await this.rewardToken.balanceOf(this.unipool.address)).to.be.bignumber.equal(web3.utils.toWei('1000'));
            expect(await this.rewardToken.balanceOf(this.unipoolRewardDepositor.address)).to.be.bignumber.equal('0');
        });
    });
});
