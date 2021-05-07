pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./TokenManagerHook.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, address user) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
    }

    function withdraw(uint256 amount, address user) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);
    }
}

contract Unipool is LPTokenWrapper, TokenManagerHook {
    IERC20 public rewardToken;
    uint256 public constant DURATION = 30 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(IERC20 _rewardToken) public {
        require(address(_rewardToken) != address(0), "reward token not present");
        rewardToken = _rewardToken;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount, address user) internal updateReward(user) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount, user);
        emit Staked(user, amount);
    }

    function withdraw(uint256 amount, address user) internal updateReward(user) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount, user);
        emit Withdrawn(user, amount);
    }

    function getReward() external updateReward(msg.sender){
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 _amount)
        external
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = _amount.div(DURATION);
        } else {
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            uint256 leftoverReward = remainingTime.mul(rewardRate);
            uint256 newRewardRate = _amount.add(leftoverReward).div(DURATION);
            require(newRewardRate >= rewardRate, "New reward rate too low");
            rewardRate = newRewardRate;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);

        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit RewardAdded(_amount);
    }

    /**
     * @dev Overrides TokenManagerHook's `_onTransfer`
     */
    function _onTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        if (_from == address(0)) { // Token mintings (wrapping tokens)
            stake(_amount, _to);
            return true;
        } else if (_to == address(0)) { // Token burning (unwrapping tokens)
            withdraw(_amount, _from);
            return true;
        } else { // Standard transfer
            withdraw(_amount, _from);
            stake(_amount, _to);
            return true;
        }
    }
}
