pragma solidity ^0.5.0;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}