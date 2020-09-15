pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Unipool.sol";

contract UnipoolFactory {
    mapping(address => address) public pools;

    function createUnipool(
        address _uniswapTokenExchange
    ) public returns (address) {
        require(pools[_uniswapTokenExchange] == address(0), "Pool already exists.");
        pools[_uniswapTokenExchange] = address(
            new Unipool(IERC20(_uniswapTokenExchange))
        );

        // NOTICE(onbjerg): This is temporary until conviction voting can
        // call `Unipool#notifyRewardAmount` itself
        new UnipoolBalanceProxy(Unipool(pools[_uniswapTokenExchange]));

        return pools[_uniswapTokenExchange];
    }
}
