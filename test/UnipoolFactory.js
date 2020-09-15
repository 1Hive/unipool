const { BN, expectRevert } = require('openzeppelin-test-helpers');
const { expect } = require('chai');

const UniswapToken = artifacts.require('UniswapTokenMock');
const TradedToken = artifacts.require('HoneyTokenMock');
const UnipoolFactory = artifacts.require('UnipoolFactory');

contract('UnipoolFactory', function ([_, wallet1, wallet2, wallet3, wallet4]) {
    describe('UnipoolFactory', async function () {
        beforeEach(async function () {
            this.uniswapToken = await UniswapToken.new();
            this.tradedToken = await TradedToken.new(wallet1);
            this.factory = await UnipoolFactory.new();
        });

        it('creates a new Unipool for a given LP token', async function () {
            expect(await this.factory.createUnipool(this.uniswapToken.address)).to.be.a('string');
        });

        it('does not allow duplicate Unipools', async function () {
            expect(await this.factory.createUnipool(this.uniswapToken.address)).to.be.a('string');
            expectRevert(await this.factory.createUnipool(this.uniswapToken.address), 'Pool already exists.');
        });
    });
});
