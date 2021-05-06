pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";
import "./UnipoolRewardDepositor.sol";

contract UnipoolFactory {

    struct PoolInfo {
        Unipool pool;
        UnipoolRewardDepositor proxy;
    }

    mapping(address => PoolInfo) public pools;

    function createUnipool(
        IERC20 _uniswapTokenExchange,
        IERC20 _rewardToken
    ) public returns (Unipool) {
        PoolInfo storage poolInfo = pools[address(_uniswapTokenExchange)];
        require(address(poolInfo.pool) == address(0), "Pool already exists");

        poolInfo.pool = new Unipool(_uniswapTokenExchange, _rewardToken);
        return poolInfo.pool;
    }

    function createRewardDepositor(
        IERC20 _uniswapTokenExchange,
        IERC20 _rewardToken
    ) public returns (UnipoolRewardDepositor) {
        PoolInfo storage poolInfo = pools[address(_uniswapTokenExchange)];
        require(address(poolInfo.pool) != address(0), "Pool doesn't exist");

        poolInfo.proxy = new UnipoolRewardDepositor(poolInfo.pool, _rewardToken);
        return poolInfo.proxy;
    }

    function createUnipoolWithDepositor(
        IERC20 _uniswapTokenExchange,
        IERC20 _rewardToken
    ) public returns (Unipool, UnipoolRewardDepositor) {
        Unipool pool = createUnipool(_uniswapTokenExchange, _rewardToken);
        UnipoolRewardDepositor proxy = createRewardDepositor(_uniswapTokenExchange, _rewardToken);

        return (pool, proxy);
    }
}
