// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondERC20 is ERC20 {
    constructor() ERC20("Diamond Reward Token", "DRT") {}

    modifier onlyDiamond() {
        require(LibDiamond.contractOwner() == msg.sender, "Not authorized");
        _;
    }

    function mint(address to, uint256 amount) external onlyDiamond {
        _mint(to, amount);
    }
}
