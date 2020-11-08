pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "../external_interfaces/IUniswapV2Pair.sol";

contract UniswapPairMock is ERC20Mintable, IUniswapV2Pair {
    IERC20 public token0;
    IERC20 public token1;

    constructor(IERC20 _token0, IERC20 _token1) public ERC20Mintable() {
        token0 = _token0;
        token1 = _token1;
    }
}