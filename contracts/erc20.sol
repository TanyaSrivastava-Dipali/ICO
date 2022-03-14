pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() public ERC20("MyToken", "MTK") {
        _mint(_msgSender(), 100000000000000000000000000000000000);
    }
}
