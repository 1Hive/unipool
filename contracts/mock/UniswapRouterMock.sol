pragma solidity ^0.5.0;

import "../external_interfaces/IUniswapV2Router01.sol";

contract UniswapRouterMock is IUniswapV2Router01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        return (amountADesired, amountBDesired, 1);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        uint[] memory amts = new uint[](2);
        amts[0] = amountIn;
        amts[1] = amountOutMin;
        return amts;
    }
}