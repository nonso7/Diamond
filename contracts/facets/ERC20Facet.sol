// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDiamondERC20 {
    function mint(address to, uint256 amount) external;
}

contract ERC20Stacking {
    
    uint256 public constant SECONDS_PER_YEAR = 31_536_000;

    event Staked(address indexed staker, uint256 indexed amount);
    event Withdraw(
        address indexed staker,
        uint256 indexed amountToBeTransferred,
        uint256 rewardYield
    );

    function setERC20Token(address _erc20Token) external {
        require(_erc20Token != address(0), "Invalid token address");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.erc20Token = _erc20Token;
    }

    function stakeERC20(uint256 _amount) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(_amount > 0, "zero value isn't allowed");
        require(
            s.noOfdays > 0,
            "State the duration you want to stake your token"
        );

        require(
            IERC20(s.erc20Token).allowance(msg.sender, address(this)) >=
                _amount,
            "ERC20: Transfer amount exceeds allowance"
        );

        s.erc20Stakes[msg.sender] += _amount;
        s.erc20StakeTimestamp[msg.sender] = block.timestamp;
        s.created = true;

        IERC20(s.erc20Token).transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function getBalance() public view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return s.erc20Stakes[msg.sender];
    }

    function withdrawToken() external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        // Get user's staked balance
        uint256 userBalance = s.erc20Stakes[msg.sender];
        require(userBalance > 0, "You have no staked tokens");

        require(!s.erc20Withdrawn[msg.sender], "You have already withdrawn");

        // Check staking duration
        require(
            block.timestamp >= s.erc20StakeTimestamp[msg.sender] + s.noOfdays,
            "Staking duration not met"
        );

        // Calculate reward
        uint256 rewardYield = calculateReward();

        // Ensure the staking contract has enough reward tokens
        require(
            s.erc20RewardToken != address(0),
            "Reward token not configured"
        );
        require(
            IERC20(s.erc20RewardToken).balanceOf(address(this)) >= rewardYield,
            "Insufficient reward tokens"
        );

        // Reset state BEFORE transfers
        s.erc20Stakes[msg.sender] = 0;
        s.erc20Withdrawn[msg.sender] = true;

        // Transfer back staked tokens
        IERC20(s.erc20Token).transfer(msg.sender, userBalance);

        // Mint reward tokens
        IDiamondERC20(s.erc20RewardToken).mint(msg.sender, rewardYield);

        emit Withdraw(msg.sender, userBalance, rewardYield);
    }

    function calculateReward() public view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        // Check if there's an active stake
        if (
            s.erc20Stakes[msg.sender] == 0 ||
            s.erc20StakeTimestamp[msg.sender] == 0
        ) {
            return 0;
        }

        uint256 totalStaked = s.erc20Stakes[msg.sender];
        uint256 timeElapsed = block.timestamp -
            s.erc20StakeTimestamp[msg.sender];

        // Ensure staking duration is met
        if (timeElapsed < s.noOfdays) {
            return 0;
        }

        // Use the constant SECONDS_PER_YEAR instead of redeclaring it
        uint256 baseReward = (totalStaked * s.apr * timeElapsed) /
            SECONDS_PER_YEAR;

        // Apply decay (ensures decay is never negative)
        uint256 decayFactor = (100 - s.decayRate);
        uint256 finalReward = (baseReward * decayFactor) / 100;

        return finalReward;
    }

    function getERC20Token() external view returns (address) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return s.erc20Token;
    }

    function setStakingDuration(uint256 _days) external {
        require(_days > 0, "Duration must be greater than zero");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.noOfdays = _days;
    }

    function getContractBalance() public view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return IERC20(s.erc20Token).balanceOf(address(this));
    }

    function getCalculateReward() public view returns (uint256) {
        return calculateReward();
    }

    function setAPR(uint256 _apr) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.apr = _apr;
    }

    function setDecayRate(uint256 _decayRate) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.decayRate = _decayRate;
    }

    function setRewardToken(address _rewardToken) external {
        require(_rewardToken != address(0), "Invalid reward token address");
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.erc20RewardToken = _rewardToken;
    }
}