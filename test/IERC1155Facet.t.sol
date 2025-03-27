// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../test/mocks/MockERC1155.sol";

contract ERC1155MockTest is Test {
    ERC1155Mock public token;
    
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    
    uint256 constant TOKEN_ID_1 = 1;
    uint256 constant TOKEN_ID_2 = 2;
    uint256 constant MINT_AMOUNT = 100;
    
    function setUp() public {
        // Deploy the ERC1155Mock token with a URI
        token = new ERC1155Mock("https://example.com/token/{id}.json");
    }
    
    function testMint() public {
        // Mint a single token type to user1
        token.mint(user1, TOKEN_ID_1, MINT_AMOUNT, "");
        
        // Check balance
        assertEq(token.balanceOf(user1, TOKEN_ID_1), MINT_AMOUNT, "User should have the minted tokens");
    }
    
    function testMintBatch() public {
        // Prepare arrays for batch minting
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = MINT_AMOUNT;
        amounts[1] = MINT_AMOUNT * 2;
        
        // Mint batch to user2
        token.mintBatch(user2, ids, amounts, "");
        
        // Check balances
        assertEq(token.balanceOf(user2, TOKEN_ID_1), MINT_AMOUNT, "User should have the correct amount of token 1");
        assertEq(token.balanceOf(user2, TOKEN_ID_2), MINT_AMOUNT * 2, "User should have the correct amount of token 2");
    }
    
    function testTransferSingle() public {
        // Mint tokens to user1
        token.mint(user1, TOKEN_ID_1, MINT_AMOUNT, "");
        
        // Transfer tokens from user1 to user2
        vm.prank(user1);
        token.safeTransferFrom(user1, user2, TOKEN_ID_1, MINT_AMOUNT / 2, "");
        
        // Check balances after transfer
        assertEq(token.balanceOf(user1, TOKEN_ID_1), MINT_AMOUNT / 2, "Sender balance should be reduced");
        assertEq(token.balanceOf(user2, TOKEN_ID_1), MINT_AMOUNT / 2, "Receiver balance should be increased");
    }
    
    function testTransferBatch() public {
        // Prepare arrays for batch minting
        uint256[] memory ids = new uint256[](2);
        ids[0] = TOKEN_ID_1;
        ids[1] = TOKEN_ID_2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = MINT_AMOUNT;
        amounts[1] = MINT_AMOUNT * 2;
        
        // Mint batch to user1
        token.mintBatch(user1, ids, amounts, "");
        
        // Prepare arrays for batch transfer
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = MINT_AMOUNT / 2;
        transferAmounts[1] = MINT_AMOUNT;
        
        // Transfer batch from user1 to user2
        vm.prank(user1);
        token.safeBatchTransferFrom(user1, user2, ids, transferAmounts, "");
        
        // Check balances after transfer
        assertEq(token.balanceOf(user1, TOKEN_ID_1), MINT_AMOUNT / 2, "Sender balance of token 1 should be reduced");
        assertEq(token.balanceOf(user1, TOKEN_ID_2), MINT_AMOUNT, "Sender balance of token 2 should be reduced");
        assertEq(token.balanceOf(user2, TOKEN_ID_1), MINT_AMOUNT / 2, "Receiver balance of token 1 should be increased");
        assertEq(token.balanceOf(user2, TOKEN_ID_2), MINT_AMOUNT, "Receiver balance of token 2 should be increased");
    }
    
    function testApprovalForAll() public {
        // Set approval for user2 to manage user1's tokens
        vm.prank(user1);
        token.setApprovalForAll(user2, true);
        
        // Check approval status
        assertTrue(token.isApprovedForAll(user1, user2), "User2 should be approved for all of User1's tokens");
        
        // Mint tokens to user1
        token.mint(user1, TOKEN_ID_1, MINT_AMOUNT, "");
        
        // User2 transfers tokens on behalf of user1 to themselves
        vm.prank(user2);
        token.safeTransferFrom(user1, user2, TOKEN_ID_1, MINT_AMOUNT / 2, "");
        
        // Check balances after transfer
        assertEq(token.balanceOf(user1, TOKEN_ID_1), MINT_AMOUNT / 2, "User1 balance should be reduced");
        assertEq(token.balanceOf(user2, TOKEN_ID_1), MINT_AMOUNT / 2, "User2 balance should be increased");
    }
    
    function testURI() public {
        // Check the URI format
        string memory expectedURI = "https://example.com/token/{id}.json";
        string memory actualURI = token.uri(TOKEN_ID_1);
        
        assertEq(actualURI, expectedURI, "Token URI should match the expected format");
    }
}