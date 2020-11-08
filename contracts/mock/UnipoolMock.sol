pragma solidity ^0.5.0;

import "../../contracts/Unipool.sol";

contract UnipoolMock is Unipool {

    constructor(IERC20 _uniswapTokenExchange, IERC20 _tradedToken, IUniswapV2Router01 _uniswapRouter) Unipool(_uniswapTokenExchange, _uniswapRouter) public {
        uniswapTokenExchange = _uniswapTokenExchange;
        tradedToken = _tradedToken;
    }
}
