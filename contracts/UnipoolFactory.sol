pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Unipool.sol";

contract UnipoolFactory {
    mapping(address => address) public pools;

    function createUnipool(
        IERC20 _uniswapTokenExchange
    ) public view returns (address) {
        require(pools[_uniswapTokenExchange] == address(0), "Pool already exists.");
        pools[_uniswapTokenExchange] = new Unipool(_uniswapTokenExchange);

        return pools[_uniswapTokenExchange];
    }
}
