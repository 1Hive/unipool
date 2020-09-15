pragma solidity ^0.5.0;

import "../../contracts/Unipool.sol";

contract UnipoolMock is Unipool {

    constructor(IERC20 _uniswapTokenExchange, IERC20 _tradedToken) Unipool(_uniswapTokenExchange) public {
        uniswapTokenExchange = _uniswapTokenExchange;
        tradedToken = _tradedToken;
    }
}
