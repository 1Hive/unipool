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

            await this.uniswapToken.mint(wallet1, web3.utils.toWei('1000'));
            await this.uniswapToken.mint(wallet2, web3.utils.toWei('1000'));
            await this.uniswapToken.mint(wallet3, web3.utils.toWei('1000'));
            await this.uniswapToken.mint(wallet4, web3.utils.toWei('1000'));

            await this.tradedToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet1 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet1 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet2 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet3 });
            await this.uniswapToken.approve(this.unipool.address, new BN(2).pow(new BN(255)), { from: wallet4 });
        });

        it('creates a new Unipool for a given LP token', async function () {
            expect(await this.factory.createUnipool(this.uniswapToken)).to.be.a('string');
        });

        it('does not allow duplicate Unipools', async function () {
            expect(await this.factory.createUnipool(this.uniswapToken)).to.be.a('string');
            expectRevert(await this.factory.createUnipool(this.uniswapToken), 'Pool already exists.');
        });
    });
});
