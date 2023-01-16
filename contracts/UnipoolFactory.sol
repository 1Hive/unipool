pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";
import "./UnipoolRewardDepositor.sol";

// Rinkeby deployment: 0x710D70591C70B1aA96d558269193F0e59F52E154
// xDai deployment: 0xD38EB36B7E8b126Ff1E9fDD007bC4050B6C6aB7c
// Goerli deployment: 0x67e278df46fce316aae1c67007d89c65c4257b7b

contract UnipoolFactory {
    event NewUnipool(Unipool unipool);
    event NewRewardDepositor(UnipoolRewardDepositor unipoolRewardDepositor);

    function newUnipool(IERC20 _rewardToken) public returns (Unipool) {
        Unipool unipool = new Unipool(_rewardToken);
        emit NewUnipool(unipool);

        return unipool;
    }

    function newUnipoolWithDepositor(IERC20 _rewardToken)
        public
        returns (Unipool, UnipoolRewardDepositor)
    {
        Unipool unipool = newUnipool(_rewardToken);
        UnipoolRewardDepositor unipoolRewardDepositor = new UnipoolRewardDepositor(
                unipool,
                _rewardToken
            );
        emit NewRewardDepositor(unipoolRewardDepositor);

        return (unipool, unipoolRewardDepositor);
    }
}
