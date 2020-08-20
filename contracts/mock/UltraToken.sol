pragma solidity ^0.5.9;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract UltraToken is ERC20Pausable, Ownable {
    using SafeMath for uint256;
    //  using Math     for uint256;

    string  private _name = "Ultra Token";
    string  private _symbol = "UOS";
    uint8   private _decimals = 4;      // the token precision on UOS mainnet is 4, can be adjusted there as necessary.

    /*  0-------------------------------------->  time in month(30 days)
     *  ^               ^                   ^
     *  |               |                   |
     * deploy         start     ...        end
     *                10.00%    ...       20.00%    adds up to 100.00%
     */
    uint256 private _deployTime;                // the deployment time of the contract
    uint256 private _month = 30 days;           // time unit
    struct VestingContract {
        uint256[]   basisPoints;    // the basis points array of each vesting. The last one won't matter, cause we give the remainder to the user at last, but the sum will be validated against 10000
        uint256     startMonth;     // the index of the month at the beginning of which the first vesting is available
        uint256     endMonth;       // the index of the month at the beginning of which the last vesting is available; _endMonth = _startMonth + _basisPoints.length -1;
    }

    struct BuyerInfo {
        uint256 total;          // the total number of tokens purchased by the buyer
        uint256 claimed;        // the number of tokens has been claimed so far
        string  contractName;   // with what contract the buyer purchased the tokens
    }

    mapping (string => VestingContract) private _vestingContracts;
    mapping (address => BuyerInfo)      private _buyerInfos;

    mapping (address => string) private _keys;              // ethereum to eos public key mapping
    mapping (address => bool)   private _updateApproval;    // whether allow an account to update its registerred eos key

    constructor() public {
        _mint(address(this), uint256(1000000000).mul(10**uint256(_decimals)));  // mint all tokens and send to the contract, 1,000,000,000 UOS;
        _deployTime = block.timestamp;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function deployTime() public view returns (uint256) {
        return _deployTime;
    }

    function buyerInformation() public view returns (uint256, uint256, string memory) {
        BuyerInfo storage buyerInfo = _buyerInfos[msg.sender];
        return (buyerInfo.total, buyerInfo.claimed, buyerInfo.contractName );
    }

    function nextVestingDate() public view returns (uint256) {
        BuyerInfo storage buyerInfo = _buyerInfos[msg.sender];
        require(buyerInfo.total > 0, "Buyer does not exist");
        VestingContract storage vestingContract = _vestingContracts[buyerInfo.contractName];
        uint256 currentMonth = block.timestamp.sub(_deployTime).div(_month);
        if(currentMonth < vestingContract.startMonth) {
            return _deployTime.add(vestingContract.startMonth.mul(_month));
        } else if(currentMonth >= vestingContract.endMonth) {
            return _deployTime.add(vestingContract.endMonth.mul(_month));
        } else {
            return _deployTime.add(currentMonth.add(1).mul(_month));
        }
    }

    event SetVestingContract(string contractName, uint256[] basisPoints, uint256 startMonth);

    function setVestingContract(string memory contractName, uint256[] memory basisPoints, uint256 startMonth) public onlyOwner whenNotPaused returns (bool) {
        VestingContract storage vestingContract = _vestingContracts[contractName];
        require(vestingContract.basisPoints.length == 0, "can't change an existing contract");
        uint256 totalBPs = 0;
        for(uint256 i = 0; i < basisPoints.length; i++) {
            totalBPs = totalBPs.add(basisPoints[i]);
        }
        require(totalBPs == 10000, "invalid basis points array"); // this also ensures array length is not zero

        vestingContract.basisPoints = basisPoints;
        vestingContract.startMonth  = startMonth;
        vestingContract.endMonth    = startMonth.add(basisPoints.length).sub(1);

        emit SetVestingContract(contractName, basisPoints, startMonth);
        return true;
    }

    event ImportBalance(address[] buyers, uint256[] tokens, string contractName);

    // import balance for a group of user with a specific contract terms
    function importBalance(address[] memory buyers, uint256[] memory tokens, string memory contractName) public onlyOwner whenNotPaused returns (bool) {
        require(buyers.length == tokens.length, "buyers and balances mismatch");

        VestingContract storage vestingContract = _vestingContracts[contractName];
        require(vestingContract.basisPoints.length > 0, "contract does not exist");

        for(uint256 i = 0; i < buyers.length; i++) {
            require(tokens[i] > 0, "cannot import zero balance");
            BuyerInfo storage buyerInfo = _buyerInfos[buyers[i]];
            require(buyerInfo.total == 0, "have already imported balance for this buyer");
            buyerInfo.total = tokens[i];
            buyerInfo.contractName = contractName;
        }

        emit ImportBalance(buyers, tokens, contractName);
        return true;
    }

    event Claim(address indexed claimer, uint256 claimed);

    function claim() public whenNotPaused returns (bool) {
        uint256 canClaim = claimableToken();

        require(canClaim > 0, "No token is available to claim");

        _buyerInfos[msg.sender].claimed = _buyerInfos[msg.sender].claimed.add(canClaim);
        _transfer(address(this), msg.sender, canClaim);

        emit Claim(msg.sender, canClaim);
        return true;
    }

    // the number of token can be claimed by the msg.sender at the moment
    function claimableToken() public view returns (uint256) {
        BuyerInfo storage buyerInfo = _buyerInfos[msg.sender];

        if(buyerInfo.claimed < buyerInfo.total) {
            VestingContract storage vestingContract = _vestingContracts[buyerInfo.contractName];
            uint256 currentMonth = block.timestamp.sub(_deployTime).div(_month);

            if(currentMonth < vestingContract.startMonth) {
                return uint256(0);
            }

            if(currentMonth >= vestingContract.endMonth) { // vest the unclaimed token all at once so there's no remainder
                return buyerInfo.total.sub(buyerInfo.claimed);
            } else {
                uint256 claimableIndex = currentMonth.sub(vestingContract.startMonth);
                uint256 canClaim = 0;
                for(uint256 i = 0; i <= claimableIndex; ++i) {
                    canClaim = canClaim.add(vestingContract.basisPoints[i]);
                }
                return canClaim.mul(buyerInfo.total).div(10000).sub(buyerInfo.claimed);
            }
        }
        return uint256(0);
    }

    event SetKey(address indexed buyer, string EOSKey);

    function _register(string memory EOSKey) internal {
        require(bytes(EOSKey).length > 0 && bytes(EOSKey).length <= 64, "EOS public key length should be less than 64 characters");
        _keys[msg.sender] = EOSKey;

        emit SetKey(msg.sender, EOSKey);
    }

    function register(string memory EOSKey) public whenNotPaused returns (bool) {
        _register(EOSKey);
        return true;
    }

    function keyOf() public view returns (string memory) {
        return _keys[msg.sender];
    }

    event SetUpdateApproval(address indexed buyer, bool isApproved);

    function setUpdateApproval(address buyer, bool isApproved) public onlyOwner returns (bool) {
        require(balanceOf(buyer) > 0 || _buyerInfos[buyer].total > 0, "This account has no token"); // allowance will not be considered
        _updateApproval[buyer] = isApproved;

        emit SetUpdateApproval(buyer, isApproved);
        return true;
    }

    function updateApproved() public view returns (bool) {
        return _updateApproval[msg.sender];
    }

    function update(string memory EOSKey) public returns (bool) {
        require(_updateApproval[msg.sender], "Need approval from ultra after contract is frozen");
        _register(EOSKey);
        return true;
    }

}
