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
    // HONEY
    IERC20 public tradedToken = IERC20(0x71850b7E9Ee3f13Ab46d67167341E4bDc905Eef9);
    IERC20 public reinvestableToken = IERC20(address(0));
    IUniswapV2Router01 public uniswapRouter = IUniswapV2Router01(0x1C232F01118CB8B424793ae03F870aa7D0ac7f77);

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

    constructor(IERC20 _uniswapTokenExchange, IUniswapV2Router01 _uniswapRouter, IERC20 _tradedToken) public {
        uniswapTokenExchange = _uniswapTokenExchange;
        uniswapRouter = _uniswapRouter;
        tradedToken = _tradedToken;

        IUniswapV2Pair pair = IUniswapV2Pair(address(uniswapTokenExchange));

        if (pair.token0() != address(tradedToken) && pair.token1() != address(tradedToken)) {
            // We can only reinvest if we're giving rewards in one side of the pair (currently)
            reinvestableToken = IERC20(address(0));
        } else {
            if (pair.token0() == address(tradedToken)) {
                reinvestableToken = IERC20(pair.token1());
            } else {
                reinvestableToken = IERC20(pair.token0());
            }
            tradedToken.approve(address(uniswapRouter), (2**256)-1);
            reinvestableToken.approve(address(uniswapRouter), (2**256)-1);
        }
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
            tradedToken.safeTransfer(msg.sender, reward);
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

        tradedToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit RewardAdded(_amount);
    }
    
    function reinvest(uint256 minTokens) public updateReward(msg.sender) {
        require(address(reinvestableToken) != address(0), "Farmed token is not one side of pair");

        uint256 reward = earned(msg.sender);
        require(reward > 0, "Nothing to reinvest");
        
        (uint256 liquidity, uint256 remainingReward) = poolHny(reward, minTokens);
        rewards[msg.sender] = remainingReward;
        super.stakeInternal(liquidity);

        emit ReinvestedReward(msg.sender, reward.sub(remainingReward), liquidity);
    }
    
    function poolHny(uint256 hnyAmt, uint256 minTokens) private returns(uint256 lpTokens, uint256 remainingHny) {
        // convert half to target token
        uint256 hnyToConvert = hnyAmt.div(2);
        
        address[] memory path = new address[](2);
        path[0] = address(tradedToken);
        path[1] = address(reinvestableToken);
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(hnyToConvert, minTokens, path, address(this), block.timestamp);

        // We exchanged this amount of honey in the swap, remove it from the current balance
        hnyAmt = hnyAmt.sub(amounts[0]);

        // Use our whole balance of `reinvestableToken`, not just what we got back from the swap.
        // This makes sure that shavings of `reinvestableToken` don't accumulate, dead, in our wallet.
        // The next user to call this method will always either leave a few shavings themselves,
        // or will receive the balance back in `tradedToken` instead, which we do account for per-user.
        uint256 reinvestableBalance = reinvestableToken.balanceOf(address(this));
        
        // add liquidity
        (uint a, uint b, uint liquidity) = 
            uniswapRouter.addLiquidity(address(tradedToken),
                                       address(reinvestableToken),
                                       hnyToConvert,
                                       reinvestableBalance,
                                       0, 0, // min
                                       address(this),
                                       block.timestamp);
        
        // now also remove the amount of liquidity we added for the final total
        return (liquidity, hnyAmt.sub(a));
    }
}
