pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";
import "./UnipoolBalanceProxy.sol";

contract UnipoolFactory {

    struct PoolInfo {
        Unipool pool;
        UnipoolBalanceProxy proxy;
    }

    IERC20 rewardToken;

    mapping(address => PoolInfo) public pools;

    constructor(IERC20 _rewardToken) public {
        require(_rewardToken != IERC20(0), "Need a nonzero traded token");
        rewardToken = _rewardToken;
    }

    function createUnipool(
        IERC20 _uniswapTokenExchange,
        IUniswapV2Router01 _uniswapRouter
    ) public returns (Unipool) {
        PoolInfo storage poolInfo = pools[address(_uniswapTokenExchange)];
        require(address(poolInfo.pool) == address(0), "Pool already exists");

        poolInfo.pool = new Unipool(_uniswapTokenExchange, _uniswapRouter, rewardToken);
        return poolInfo.pool;
    }

    function createBalanceProxy(
        IERC20 _uniswapTokenExchange
    ) public returns (UnipoolBalanceProxy) {
        PoolInfo storage poolInfo = pools[address(_uniswapTokenExchange)];
        require(address(poolInfo.pool) != address(0), "Pool doesn't exist");

        poolInfo.proxy = new UnipoolBalanceProxy(poolInfo.pool);
        return poolInfo.proxy;
    }

    function createUnipoolWithProxy(
        IERC20 _uniswapTokenExchange,
        IUniswapV2Router01 _uniswapRouter
    ) public returns (Unipool, UnipoolBalanceProxy) {
        Unipool pool = createUnipool(_uniswapTokenExchange, _uniswapRouter);
        UnipoolBalanceProxy proxy = createBalanceProxy(_uniswapTokenExchange);

        return (pool, proxy);
    }
}
