pragma solidity ^0.5.0;

import "../external_interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract UniswapRouterMock is IUniswapV2Router01 {
    using SafeMath for uint256;

    function addLiquidity(
        address //tokenA
        , address //tokenB
        , uint amountADesired
        , uint amountBDesired
        , uint //amountAMin
        , uint //amountBMin
        , address //to
        , uint //deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        return (amountADesired, amountBDesired, 1);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata //path
        , address //to
        , uint //deadline
    ) external returns (uint[] memory amounts) {
        uint[] memory amts = new uint[](2);
        amts[0] = amountIn;
        amts[1] = amountOutMin;
        return amts;
    }

    function getAmountOut(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut
    ) external pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}