// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract DAI is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 amount_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, amount_);
    }
}
