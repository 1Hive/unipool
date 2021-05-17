pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Unipool.sol";

contract UnipoolRewardDepositor {
    using SafeERC20 for IERC20;

    Unipool public unipool;
    IERC20 public rewardToken;

    constructor(Unipool _unipool, IERC20 _rewardToken) public {
        unipool = _unipool;
        rewardToken = _rewardToken;
    }

    function transfer() public {
        rewardToken.safeIncreaseAllowance(address(unipool), rewardToken.balanceOf(address(this)));
        unipool.notifyRewardAmount(rewardToken.balanceOf(address(this)));
    }
}
