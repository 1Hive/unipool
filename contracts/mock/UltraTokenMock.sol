pragma solidity ^0.5.0;

import "./UltraToken.sol";

contract UltraTokenMock is UltraToken {

    constructor(address _tokenBeneficiary) UltraToken() public {
        _mint(_tokenBeneficiary, 1000000 * 1e18);
    }
}
