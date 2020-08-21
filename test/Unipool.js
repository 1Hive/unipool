const { BN, expectRevert, time } = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const UniswapToken = artifacts.require('UniswapTokenMock');
const UltraToken = artifacts.require('UltraTokenMock');
const Unipool = artifacts.require('UnipoolMock');

async function timeIncreaseTo (seconds) {
    const delay = 10 - new Date().getMilliseconds();
    await new Promise(resolve => setTimeout(resolve, delay));
    await time.increaseTo(seconds);
}

const almostEqualDiv1e18 = function (expectedOrig, actualOrig) {
    const _1e18 = new BN('10').pow(new BN('18'));
    const expected = expectedOrig.div(_1e18);
    const actual = actualOrig.div(_1e18);
    this.assert(
        expected.eq(actual) ||
        expected.addn(1).eq(actual) || expected.addn(2).eq(actual) ||
        actual.addn(1).eq(expected) || actual.addn(2).eq(expected),
        'expected #{act} to be almost equal #{exp}',
        'expected #{act} to be different from #{exp}',
        expectedOrig.toString(),
        actualOrig.toString(),
    );
};

require('chai').use(function (chai, utils) {
    chai.Assertion.overwriteMethod('almostEqualDiv1e18', function (original) {
        return function (value) {
            if (utils.flag(this, 'bignumber')) {
                var expected = new BN(value);
                var actual = new BN(this._obj);
                almostEqualDiv1e18.apply(this, [expected, actual]);
            } else {
                original.apply(this, arguments);
            }
        };
    });
});

contract('Unipool', function ([_, wallet1, wallet2, wallet3, wallet4]) {
    describe('Unipool', async function () {
        beforeEach(async function () {
            this.uniswapToken = await UniswapToken.new();
            this.ultraToken = await UltraToken.new(wallet1);
            this.unipool = await Unipool.new(this.uniswapToken.address, this.ultraToken.address);

            await this.unipool.setRewardDistribution(wallet1);
            await this.uniswapToken.mint(wallet1, web3.utils.toWei('1000'));
            await this.uniswapToken.mint(wallet2, web3.utils.toWei('1000'));
            await this.uniswapToken.mint(wallet3, web3.utils.toWei('1000'));
            await this.uniswapToken.mint(wallet4, web3.utils.toWei('1000'));

            await this.ultraToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet1 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet1 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet2 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet3 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet4 });

            this.started = (await time.latest()).addn(10);
            await timeIncreaseTo(this.started);
        });

        it('Two stakers with the same stakes wait 30 days', async function () {
            // 72000 SNX per week for 3 weeks
            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18('0');
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.equal('0');

            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet1 });
            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet2 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18('0');
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.equal('0');

            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });

            await timeIncreaseTo(this.started.add(time.duration.days(30)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('36000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('36000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('36000'));
        });

        it('Two stakers with the different (1:3) stakes wait 30 days', async function () {
            // 72000 SNX per week
            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18('0');
            expect(await this.unipool.balanceOf(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.balanceOf(wallet2)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.equal('0');

            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet1 });
            await this.unipool.stake(web3.utils.toWei('3'), { from: wallet2 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18('0');
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.equal('0');

            await timeIncreaseTo(this.started.add(time.duration.days(30)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('18000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('18000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('54000'));
        });

        it('Two stakers with the different (1:3) stakes wait 60 days', async function () {
            //
            // 1x: +----------------+ = 72k for 30 days + 18k for 60 days
            // 3x:         +--------+ =  0k for 30 days + 54k for 60 days
            //

            // 72000 SNX per week
            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });

            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet1 });

            await timeIncreaseTo(this.started.add(time.duration.days(30)));

            await this.unipool.stake(web3.utils.toWei('3'), { from: wallet2 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('72000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('72000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('0'));

            // Forward to week 3 and notifyReward weekly
            for (let i = 1; i < 3; i++) {
                await timeIncreaseTo(this.started.add(time.duration.days(30 * (i + 1))));
                await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });
            }

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('90000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('90000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('54000'));
        });

        it('Three stakers with the different (1:3:5) stakes wait 90 days', async function () {
            //
            // 1x: +----------------+--------+ = 18k for 30 days +  8k for 60 days + 12k for 90 days
            // 3x: +----------------+          = 54k for 30 days + 24k for 60 days +  0k for 90 days
            // 5x:         +-----------------+ =  0k for 30 days + 40k for 60 days + 60k for 90 days
            //

            // 72000 SNX per week for 3 weeks
            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });

            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet1 });
            await this.unipool.stake(web3.utils.toWei('3'), { from: wallet2 });

            await timeIncreaseTo(this.started.add(time.duration.days(30)));

            await this.unipool.stake(web3.utils.toWei('5'), { from: wallet3 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('18000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('18000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('54000'));

            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });
            await timeIncreaseTo(this.started.add(time.duration.days(60)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('26000')); // 18k + 8k
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('26000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('78000'));
            expect(await this.unipool.earned(wallet3)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('40000'));

            await this.unipool.exit({ from: wallet2 });

            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });
            await timeIncreaseTo(this.started.add(time.duration.days(90)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('38000')); // 18k + 8k + 12k
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('38000'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('0'));
            expect(await this.unipool.earned(wallet3)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('100000'));
        });

        it('One staker on 2 durations with gap', async function () {
            // 72000 SNX per week for 1 weeks
            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });

            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet1 });

            await timeIncreaseTo(this.started.add(time.duration.days(60)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('72000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('72000'));

            // 72000 SNX per week for 1 weeks
            await this.unipool.notifyRewardAmount(web3.utils.toWei('72000'), { from: wallet1 });

            await timeIncreaseTo(this.started.add(time.duration.days(90)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('144000'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('144000'));
        });

        it('Notify Reward Amount from mocked distribution to 10,000', async function () {
            // 10000 SNX per week for 1 weeks
            await this.unipool.notifyRewardAmount(web3.utils.toWei('10000'), { from: wallet1 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18('0');
            expect(await this.unipool.balanceOf(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.balanceOf(wallet2)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.equal('0');

            await this.unipool.stake(web3.utils.toWei('1'), { from: wallet1 });
            await this.unipool.stake(web3.utils.toWei('3'), { from: wallet2 });

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18('0');
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.equal('0');
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.equal('0');

            await timeIncreaseTo(this.started.add(time.duration.days(30)));

            expect(await this.unipool.rewardPerToken()).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('2500'));
            expect(await this.unipool.earned(wallet1)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('2500'));
            expect(await this.unipool.earned(wallet2)).to.be.bignumber.almostEqualDiv1e18(web3.utils.toWei('7500'));
        });

        it('Notify Reward reverts when notifying will reduce reward rate within same period', async function () {
            const originalAwardAmount = 10000;
            await this.unipool.notifyRewardAmount(web3.utils.toWei(originalAwardAmount.toString()), { from: wallet1 });
            await timeIncreaseTo(this.started.add(time.duration.days(20)));

            await expectRevert(this.unipool.notifyRewardAmount(web3.utils.toWei((originalAwardAmount - 9000).toString()), { from: wallet1 }),
                'New reward rate too low');
        });

        it('Notify Reward updates reward amount when notifying within same period', async function () {
            const originalAwardAmount = 10000;
            await this.unipool.notifyRewardAmount(web3.utils.toWei(originalAwardAmount.toString()), { from: wallet1 });
            const originalRewardRate = await this.unipool.rewardRate();
            await timeIncreaseTo(this.started.add(time.duration.days(20)));

            await this.unipool.notifyRewardAmount(web3.utils.toWei((originalAwardAmount).toString()), { from: wallet1 });

            expect(await this.unipool.rewardRate()).to.be.bignumber.greaterThan(originalRewardRate);
        });

        it('Notify Reward can be less when notifying in a new period', async function () {
            const originalAwardAmount = 10000;
            await this.unipool.notifyRewardAmount(web3.utils.toWei(originalAwardAmount.toString()), { from: wallet1 });
            const originalRewardRate = await this.unipool.rewardRate();
            await timeIncreaseTo(this.started.add(time.duration.days(30)));

            this.unipool.notifyRewardAmount(web3.utils.toWei((originalAwardAmount - 9000).toString()), { from: wallet1 });

            expect(await this.unipool.rewardRate()).to.be.bignumber.lessThan(originalRewardRate);
        });
    });
});
