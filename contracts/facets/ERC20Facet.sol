// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        uint256 userBalance = getBalance();
        require(userBalance != 0, "You Staked no token");
        require(!s.erc20Withdrawn[msg.sender], "You have already withdrawn");
        require(block.timestamp >= s.noOfdays, "Duration hasnt been met");

        uint256 rewardYield = calculateReward();

        uint256 amountToBeTransferred = userBalance + rewardYield;

        s.erc20Stakes[msg.sender] = 0;
        s.erc20Withdrawn[msg.sender] = true;
        IERC20(s.erc20Token).transfer(msg.sender, amountToBeTransferred);

        emit Withdraw(msg.sender, amountToBeTransferred, rewardYield);
    }

    function calculateReward() internal view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        if (s.erc20StakeTimestamp[msg.sender] == 0) return 0; // Prevent division by zero

        uint256 totalStaked = s.erc20Stakes[msg.sender];
        uint256 stakedTime = block.timestamp -
            s.erc20StakeTimestamp[msg.sender];

        uint256 decayFactor = s.decayRate > 0 ? (100 - s.decayRate) : 100;

        return
            (s.apr * totalStaked * decayFactor * stakedTime) /
            (100 * 100 * SECONDS_PER_YEAR);
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
}
