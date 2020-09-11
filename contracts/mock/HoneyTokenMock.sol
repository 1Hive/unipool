pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";

contract HoneyTokenMock is ERC20Mintable {

    constructor(address _tokenBeneficiary) public {
        _mint(_tokenBeneficiary, 1000000 * 1e18);
    }
}
