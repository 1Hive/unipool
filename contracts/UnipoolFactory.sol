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
    ) public returns (address) {
        require(address(pools[address(_uniswapTokenExchange)].pool) == address(0), "Pool already exists");
        pools[address(_uniswapTokenExchange)].pool = new Unipool(_uniswapTokenExchange);

        return address(pools[address(_uniswapTokenExchange)].pool);
    }

    function createBalanceProxy(
        IERC20 _uniswapTokenExchange
    ) public returns (address) {
        require(address(pools[address(_uniswapTokenExchange)].pool) != address(0), "Pool doesn't exist");
        pools[address(_uniswapTokenExchange)].proxy = new UnipoolBalanceProxy(
            pools[address(_uniswapTokenExchange)].pool
        );

        return address(pools[address(_uniswapTokenExchange)].proxy);
    }

    function createUnipoolWithProxy(
        IERC20 _uniswapTokenExchange
    ) public returns (address, address) {
        address pool = createUnipool(_uniswapTokenExchange);
        address proxy = createBalanceProxy(_uniswapTokenExchange);

        return (pool, proxy);
    }
}
