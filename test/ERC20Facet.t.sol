// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Stacking} from "../contracts/facets/ERC20Facet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "./mocks/Mock.sol";
import {LibAppStorage} from "../contracts/libraries/LibAppStorage.sol";

contract ERC20StakingTest is Test {
    ERC20Stacking stakingContract;
    ERC20Mock rewardToken;
    address user = address(1);

    function setUp() public {
        rewardToken = new ERC20Mock(
            "MockToken",
            "MTK",
            1_000_000 ether,
            address(this)
        );
        stakingContract = new ERC20Stacking();

        // Set ERC20 token for staking
        vm.prank(address(this));
        stakingContract.setERC20Token(address(rewardToken));

        // 🛠 Fix: Set staking duration to avoid revert
        vm.prank(address(this));
        stakingContract.setStakingDuration(30); // Set to 30 days

        // Mint tokens & approve staking contract
        rewardToken.mint(user, 1_000 ether);
        vm.prank(user);
        rewardToken.approve(address(stakingContract), 1_000 ether);
    }

    function testSetERC20Token() public {
        // ✅ Retrieve and check ERC20 token
        address storedToken = stakingContract.getERC20Token();
        assertEq(
            storedToken,
            address(rewardToken),
            "ERC20 token not set correctly"
        );
        console.log("ERC20 token set successfully:", storedToken);
    }

    function testStakeERC20() public {
        uint256 stakeAmount = 100 ether;

        // ✅ Ensure user has enough tokens (already minted in setUp())
        uint256 initialUserBalance = rewardToken.balanceOf(user);
        assertEq(
            initialUserBalance,
            1_000 ether,
            "User should have initial balance"
        );

        // ✅ Approve staking contract
        vm.prank(user);
        rewardToken.approve(address(stakingContract), stakeAmount);

        // ✅ Stake tokens
        vm.prank(user);
        stakingContract.stakeERC20(stakeAmount);

        // ✅ Check the user's staked balance
        uint256 userStakedBalance = stakingContract.getBalance();
        assertEq(userStakedBalance, stakeAmount, "Stake amount mismatch");

        // ✅ Ensure the contract received the tokens
        uint256 contractBalance = rewardToken.balanceOf(
            address(stakingContract)
        );
        assertEq(
            contractBalance,
            stakeAmount,
            "Contract did not receive the tokens"
        );

        console.log("User successfully staked:", stakeAmount);
    }

    function testWithdrawERC20() public {
        uint256 stakeAmount = 100 ether;

        // ✅ Stake first
        vm.prank(user);
        stakingContract.stakeERC20(stakeAmount);

        // ✅ Advance time to simulate staking period
        vm.warp(block.timestamp + 30 days);

        // ✅ Withdraw tokens
        vm.prank(user);
        stakingContract.withdrawToken();

        // ✅ Ensure balance is 0 after withdrawal
        uint256 stakedBalance = stakingContract.getBalance();
        assertEq(stakedBalance, 0, "Balance should be 0 after withdrawal");
        console.log("Withdrawal successful, new balance:", stakedBalance);
    }
}
