pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";
import "./UnipoolBalanceProxy.sol";

contract UnipoolFactory {

    struct PoolInfo {
        Unipool pool;
        UnipoolBalanceProxy proxy;
    }

    mapping(address => PoolInfo) public pools;

    function createUnipool(
        IERC20 _uniswapTokenExchange
    ) public returns (Unipool) {
        PoolInfo storage poolInfo = pools[address(_uniswapTokenExchange)];
        require(address(poolInfo.pool) == address(0), "Pool already exists");

        poolInfo.pool = new Unipool(_uniswapTokenExchange);
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
        IERC20 _uniswapTokenExchange
    ) public returns (Unipool, UnipoolBalanceProxy) {
        Unipool pool = createUnipool(_uniswapTokenExchange);
        UnipoolBalanceProxy proxy = createBalanceProxy(_uniswapTokenExchange);

        return (pool, proxy);
    }
}
