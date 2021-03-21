// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Polygon is ERC20 {

    constructor() ERC20("Polygon", "MATIC") {
        _mint(msg.sender, 1000);
    }
}