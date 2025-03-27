// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library LibAppStorage{
    struct AppStorage {
        address erc20RewardToken;
        address erc20Token;
        address erc721Token;
        address erc1155Token;

        mapping(address => uint256) erc20Stakes;
        mapping(address => bool) erc20Withdrawn;
        mapping(address => uint256[]) erc721Stakes;
        mapping(address => bool) erc721Withdrawn;
        mapping(address => mapping(uint256 => uint256)) erc1155Stakes;
        mapping(address => bool) erc1155Withdrawn;

        mapping(address => uint256) erc20StakeTimestamp;
        mapping(address => mapping(uint256 => uint256)) erc721StakeTimestamp;
        mapping(address => mapping(uint256 => uint256)) erc1155StakeTimestamp;

        uint256 apr;
        uint256 nftRewardRate;
        uint256 erc1155Multiplier;

        uint256 amount;
        uint256 noOfdays;
        uint256 yearsLater;
        uint256 decayRate;
        
        bool created;

        address contractOwner;
    }


    //bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("My Staking Diamond Contract");

    function appStorage() internal pure returns (AppStorage storage ds) {
        //bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := 0
        }
    }
}