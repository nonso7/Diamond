// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDiamondERC20 {
    function mint(address to, uint256 amount) external;
}


contract ERC1155Facet {
    LibAppStorage.AppStorage s;

    uint256 public constant SECONDS_PER_YEAR = 31_536_000;


    event Staked(address indexed staker, uint256 indexed tokenId, uint256 amount);
    event Unstaked(address indexed staker, uint256 indexed tokenId, uint256 amount);

    function stakeERC1155(uint256 tokenId, uint256 amount) external {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(amount > 0, "Cannot stake zero tokens");

        IERC1155(s.erc1155Token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        s.erc1155Stakes[msg.sender][tokenId] += amount;
        s.erc1155StakeTimestamp[msg.sender][tokenId] = block.timestamp;

        emit Staked(msg.sender, tokenId, amount);
    }

    function unstakeERC1155(uint256 tokenId, uint256 amount) external {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        require(s.erc1155Stakes[msg.sender][tokenId] >= amount, "Insufficient staked balance");

        s.erc1155Stakes[msg.sender][tokenId] -= amount;
        uint256 rewardYield = calculateReward();

        IERC1155(s.erc1155Token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        IDiamondERC20(s.erc20RewardToken).mint(msg.sender, rewardYield);

        emit Unstaked(msg.sender, tokenId, amount);
    }

    function getStakedBalance(uint256 tokenId) external view returns (uint256) {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return s.erc1155Stakes[msg.sender][tokenId];
    }

    function calculateReward() public view returns (uint256) {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

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
}
