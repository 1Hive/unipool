pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "../external_interfaces/IUniswapV2Pair.sol";

contract UniswapPairMock is ERC20Mintable, IUniswapV2Pair {
    IERC20 public token0;
    IERC20 public token1;
    address public factory = address(0);
    uint112 reserveA = 10000000000000000000000000;
    uint112 reserveB = 10000000000000000000000000;

    constructor(IERC20 _token0, IERC20 _token1) public ERC20Mintable() {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view returns (uint112 _reserveA, uint112 _reserveB, uint32 timestamp) {
        return (reserveA, reserveB, 1);
    }

    function setReserves(uint112 _reserveA, uint112 _reserveB) public {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }
}