pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./external_interfaces/IUniswapV2Router01.sol";
import "./external_interfaces/IUniswapV2Pair.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public uniswapTokenExchange = IERC20(0x4505b262DC053998C10685DC5F9098af8AE5C8ad);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        stakeInternal(amount);
        uniswapTokenExchange.safeTransferFrom(msg.sender, address(this), amount);
    }

    function stakeInternal(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uniswapTokenExchange.safeTransfer(msg.sender, amount);
    }
}

contract Unipool is LPTokenWrapper {
    IERC20 public rewardToken;
    IERC20 public tradableToken;
    IUniswapV2Router01 public uniswapRouter;

    uint256 public constant DURATION = 30 days;
    uint256 public constant MAX_SLIPPAGE_BASIS_POINTS = 200;

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
    event ReinvestedReward(address indexed user, uint256 reward, uint256 lpStaked);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(IERC20 _uniswapTokenExchange, IUniswapV2Router01 _uniswapRouter, IERC20 _rewardToken) public {
        uniswapTokenExchange = _uniswapTokenExchange;
        uniswapRouter = _uniswapRouter;
        rewardToken = _rewardToken;

        tradableToken = _getPairedTokenIfRewardsTradable();
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

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
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
    
    function reinvestReward() public updateReward(msg.sender) {
        require(tradableToken != IERC20(0), "Reward token is not one side of pair");

        uint256 reward = earned(msg.sender);
        require(reward > 0, "Nothing to reinvest");
        
        (uint256 liquidity, uint256 remainingReward) = _poolReward(reward);
        rewards[msg.sender] = remainingReward;
        super.stakeInternal(liquidity);

        emit ReinvestedReward(msg.sender, reward.sub(remainingReward), liquidity);
    }
    
    function _poolReward(uint256 rewardAmount) private returns(uint256 liquidityTokens, uint256 remainingReward) {
        // convert half to target token
        uint256 rewardToConvert = rewardAmount / 2;
        // approve the amount we're going to convert
        rewardToken.approve(address(uniswapRouter), rewardToConvert);
        
        address[] memory path = new address[](2);
        path[0] = address(rewardToken);
        path[1] = address(tradableToken);

        uint256 minimumTokens = _getMinimumTokensForRewardSale(rewardToConvert);
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            rewardToConvert, 
            minimumTokens, 
            path, 
            address(this), 
            block.timestamp);

        // We exchanged this amount of the reward token in the swap, remove it from the current balance
        rewardAmount = rewardAmount.sub(amounts[0]);

        // Use our whole balance of `tradableToken`, not just what we got back from the swap.
        // This makes sure that shavings of `tradableToken` don't accumulate, dead, in our wallet.
        // The next user to call this method will always either leave a few shavings themselves,
        // or will receive the balance back in `rewardToken` instead, which we do account for per-user.
        uint256 reinvestableBalance = tradableToken.balanceOf(address(this));

        // Approve the amount we're going to try and add to the pool
        rewardToken.approve(address(uniswapRouter), rewardToConvert);
        tradableToken.approve(address(uniswapRouter), reinvestableBalance);
        
        // add liquidity
        (uint rewardTokenAdded, , uint liquidity) = 
            uniswapRouter.addLiquidity(address(rewardToken),
                                       address(tradableToken),
                                       rewardToConvert,
                                       reinvestableBalance,
                                       0, 0, // min
                                       address(this),
                                       block.timestamp);
        
        // revoke approval
        rewardToken.approve(address(uniswapRouter), 0);
        tradableToken.approve(address(uniswapRouter), 0);

        // now also remove the amount of liquidity we added for the final total
        return (liquidity, rewardAmount.sub(rewardTokenAdded));
    }

    function _getMinimumTokensForRewardSale(uint256 tradeSize) private view returns(uint256 minTokens) {
        IUniswapV2Pair pair = IUniswapV2Pair(address(uniswapTokenExchange));

        // Get reserves and order them correctly
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        (uint256 rewardReserve, uint256 foreignReserve) = 
            rewardToken == pair.token0() ? (reserve0, reserve1) : (reserve1, reserve0);
        
        // Price of our trade if the price didn't slip
        uint256 immediatePrice = tradeSize.mul(foreignReserve).div(rewardReserve);
        // The lowest we'd be willing to accept, based on max slippage
        uint256 acceptablePrice = immediatePrice.mul(10000 - MAX_SLIPPAGE_BASIS_POINTS).div(10000);
        // Preflight here mostly for the benefit of unit tests
        require(uniswapRouter.getAmountOut(tradeSize, rewardReserve, foreignReserve) >= acceptablePrice, 
            "Slippage too high for automagic reinvestment");
        return acceptablePrice;
    }

    // Gets the paired token if rewards are tradable (if one of the sides of the pair is our reward token)
    function _getPairedTokenIfRewardsTradable() private view returns (IERC20) {
        IUniswapV2Pair pair = IUniswapV2Pair(address(uniswapTokenExchange));
        if (pair.token0() == rewardToken) {
            return pair.token1();
        } else if (pair.token1() == rewardToken) {
            return pair.token0();
        } else {
            // We can only reinvest if we're giving rewards in one side of the pair (currently)
            return IERC20(0);
        }
    }
}
