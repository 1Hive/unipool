pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";
import "./UnipoolRewardDepositor.sol";

contract UnipoolFactory {

    function createUnipool(IERC20 _rewardToken) public returns (Unipool) {
        return new Unipool(_rewardToken);
    }

    function createUnipoolWithDepositor(IERC20 _rewardToken) public returns (Unipool, UnipoolRewardDepositor) {
        Unipool unipool = createUnipool(_rewardToken);
        UnipoolRewardDepositor depositor = new UnipoolRewardDepositor(unipool, _rewardToken);
        return (unipool, depositor);
    }
}
