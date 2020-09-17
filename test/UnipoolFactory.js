const { BN, expectRevert } = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const UniswapToken = artifacts.require('UniswapTokenMock');
const TradedToken = artifacts.require('HoneyTokenMock');
const UnipoolFactory = artifacts.require('UnipoolFactory');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

contract('UnipoolFactory', function ([_, wallet1, wallet2, wallet3, wallet4]) {
    describe('UnipoolFactory', async function () {
        beforeEach(async function () {
            this.uniswapToken = await UniswapToken.new();
            this.tradedToken = await TradedToken.new(wallet1);
            this.factory = await UnipoolFactory.new();
        });

        it('creates a new Unipool and proxy for a given LP token', async function () {
            await this.factory.createUnipoolWithProxy(this.uniswapToken.address);
            expect(await this.factory.pools(this.uniswapToken.address)).to.not.include({
                pool: ZERO_ADDRESS,
                proxy: ZERO_ADDRESS
            });
        });

        it('creates a new Unipool for a given LP token', async function () {
            await this.factory.createUnipool(this.uniswapToken.address);
            expect(await this.factory.pools(this.uniswapToken.address)).to.not.include({
                pool: ZERO_ADDRESS
            });
        });

        it('creates a new balance proxy for a given LP token with a pool', async function () {
            await this.factory.createUnipool(this.uniswapToken.address);
            await this.factory.createBalanceProxy(this.uniswapToken.address);
            expect(await this.factory.pools(this.uniswapToken.address)).to.not.include({
                pool: ZERO_ADDRESS,
                proxy: ZERO_ADDRESS
            });
            await expectRevert(this.factory.createBalanceProxy(ZERO_ADDRESS), 'Pool doesn\'t exist');
            expect(await this.factory.pools(ZERO_ADDRESS)).to.deep.include({
                pool: ZERO_ADDRESS,
                proxy: ZERO_ADDRESS
            });
        });

        it('does not allow duplicate Unipools', async function () {
            await this.factory.createUnipool(this.uniswapToken.address);
            await expectRevert(this.factory.createUnipool(this.uniswapToken.address), 'Pool already exists.');
        });
    });
});
