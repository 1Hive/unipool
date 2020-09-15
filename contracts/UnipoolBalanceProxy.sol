pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Unipool.sol";

contract UnipoolBalanceProxy {
    using SafeERC20 for IERC20;

    IERC20 public tradedToken = IERC20(0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9);
    Unipool public pool;

    constructor(Unipool _pool) public {
        pool = _pool;
    }

    function transfer() public {
      tradedToken.safeIncreaseAllowance(address(pool), tradedToken.balanceOf(address(this)));
      pool.notifyRewardAmount(tradedToken.balanceOf(address(this)));
    }
}
