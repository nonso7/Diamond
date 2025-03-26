// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC1155Facet {
    LibAppStorage.AppStorage s;


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

        IERC1155(s.erc1155Token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        emit Unstaked(msg.sender, tokenId, amount);
    }

    function getStakedBalance(uint256 tokenId) external view returns (uint256) {
        //LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return s.erc1155Stakes[msg.sender][tokenId];
    }
}
