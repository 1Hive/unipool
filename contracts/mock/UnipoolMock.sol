pragma solidity ^0.5.0;

import "../../contracts/Unipool.sol";

contract UnipoolMock is Unipool {

    constructor(IUniswapV2Pair _uniswapTokenExchange, IERC20 _tradedToken, IUniswapV2Router01 _uniswapRouter) Unipool(IERC20(address(_uniswapTokenExchange)), _uniswapRouter, _tradedToken) public {
    }
}
