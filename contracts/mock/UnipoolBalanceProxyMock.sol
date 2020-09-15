pragma solidity ^0.5.0;

import "../../contracts/UnipoolBalanceProxy.sol";

contract UnipoolBalanceProxyMock is UnipoolBalanceProxy {

    constructor(Unipool _pool, IERC20 _tradedToken) UnipoolBalanceProxy(_pool) public {
        tradedToken = _tradedToken;
    }
}
