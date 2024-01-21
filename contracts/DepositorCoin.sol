//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";

contract DepositorCoin is ERC20 {
    address public owner;
    
    constructor ( 
        string memory _name,
        string memory _symbol
        ) ERC20(_name,_symbol){}
    
    function mint(address to,uint256 value) external {
        require(msg.sender == owner,"DPC:only owner can Mint");
        _mint(to, value);
    }

    function burn(address from,uint256 value) external {
        require(msg.sender == owner,"DPC:only owner can Burn");
        _burn(from, value);
    }
}
    
