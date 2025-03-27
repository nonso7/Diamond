// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDiamondERC20 {
    function mint(address to, uint256 amount) external;
}

contract ERC721Facet {
    LibAppStorage.AppStorage s;

    event NFTStaked(address indexed user, uint256 indexed tokenId);
    event NFTUnstaked(address indexed user, uint256 indexed tokenId);

    function stakeERC721(uint256 _tokenId) external {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        IERC721 nft = IERC721(s.erc721Token);
        
        require(nft.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        require(s.erc721StakeTimestamp[msg.sender][_tokenId] == 0, "NFT already staked");
        
        nft.transferFrom(msg.sender, address(this), _tokenId);
        s.erc721Stakes[msg.sender].push(_tokenId);
        s.erc721StakeTimestamp[msg.sender][_tokenId] = block.timestamp;
        
        emit NFTStaked(msg.sender, _tokenId);
    }

    function unstakeERC721(uint256 _tokenId) external {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        IERC721 nft = IERC721(s.erc721Token);
        
        require(s.erc721StakeTimestamp[msg.sender][_tokenId] != 0, "NFT not staked");
        
        uint256 reward = calculateNFTReward(msg.sender, _tokenId);
        
        
        nft.transferFrom(address(this), msg.sender, _tokenId);
        IDiamondERC20(s.erc20RewardToken).transfer(msg.sender, rewardYield);
        
        emit NFTUnstaked(msg.sender, _tokenId);
    }

    function calculateNFTReward(address _user, uint256 _tokenId) public view returns (uint256) {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        uint256 stakingTime = block.timestamp - s.erc721StakeTimestamp[_user][_tokenId];
        return (stakingTime * s.nftRewardRate) / 1 days;
    }
}
