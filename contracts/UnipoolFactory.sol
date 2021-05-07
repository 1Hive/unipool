pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";
import "./UnipoolRewardDepositor.sol";

contract UnipoolFactory {

    event NewUnipool(Unipool unipool);
    event NewRewardDepositor(UnipoolRewardDepositor unipoolRewardDepositor);

    function newUnipool(IERC20 _rewardToken) public returns (Unipool) {
        Unipool unipool = new Unipool(_rewardToken);
        emit NewUnipool(unipool);

        return unipool;
    }

    function newUnipoolWithDepositor(IERC20 _rewardToken) public returns (Unipool, UnipoolRewardDepositor) {
        Unipool unipool = newUnipool(_rewardToken);
        UnipoolRewardDepositor unipoolRewardDepositor = new UnipoolRewardDepositor(unipool, _rewardToken);
        emit NewRewardDepositor(unipoolRewardDepositor);

        return (unipool, unipoolRewardDepositor);
    }
}
