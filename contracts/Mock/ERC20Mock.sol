//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "hardhat/console.sol";
import {ERC20} from "../ERC20.sol";

contract ERC20Mock is ERC20{
  constructor(
        string memory _name,
        string memory _symbol
      ) ERC20(_name, _symbol) { }

/* this mint is kind of safety net ; like only minting tokens for testing purpose in this
    Mock contract 
*/
    function mintTokens(address to, uint val) internal{
            _mint(to, val);
    }
}