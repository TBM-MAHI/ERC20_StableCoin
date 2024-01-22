//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";

contract DepositorCoin is ERC20 {
    address public owner;
    uint public unlockTime;
    //if locked tie is 2 days then depositors will be able to mint/burn after 
    // contract deployment time + 2days

    modifier isLocked {
        require(block.timestamp > unlockTime, "DPC: Funds Still Locked");
        _;
    }

    constructor ( 
        string memory _name,
        string memory _symbol,
        uint _locked_time
    ) ERC20(_name,_symbol)
        {
            unlockTime = block.timestamp + _locked_time;
        }
    
    function mint(address to,uint256 value) external isLocked {
        require(msg.sender == owner,"DPC:only owner can Mint");
        _mint(to, value);
    }

    function burn(address from,uint256 value) external isLocked{
        require(msg.sender == owner,"DPC:only owner can Burn");
        _burn(from, value);
    }
}
    
