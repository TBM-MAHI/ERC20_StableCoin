//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";

contract StableCoin is ERC20 {
    //Stablecoin is the Owner od the Depositor Cpom
//deposotie cpn contact only becomes useful when people stats deposit extra ETh (leveraged trading)
    DepositorCoin depositorCoin;
     constructor 
     ( 
        string memory _name,
        string memory _symbol
     ) ERC20(_name,_symbol){}

    function mint() external payable{
        uint256 ethUSprice=2000;
        uint stableCoinAmount = msg.value*ethUSprice;
        _mint(msg.sender, stableCoinAmount);
    }

    function burn(uint burnAmount) external {
         uint256 ethUSprice=2000;
         //REFUNDING DEPOSITED ETH
        uint refund_ETH = burnAmount/ethUSprice;
        /*example:
            1 deposited 1.3 eth = 1300 stablecoin 
            now refund_ETH = 1300000000000000000*1000/1000
            burn 1000 stable token and give back 1300000000000000000 wei/ 1.3eth
         */
        _burn(msg.sender, burnAmount);
        (bool success, ) = msg.sender.call{ value:refund_ETH }("");
        require(success); //      require(success==true);
    }
    //the function whwre extra ETH are deposited
    function depositCollateralBuffer() payable external{
        uint256 ethUSDprice=2000;
        /* iN Our Example :
         Total Depositor Coin Supply : 250
         Total Dollar : 500$
         price of 1 depositor Coin In USD = 0.5 USD */
        uint256 surplusInUDS = 500; //explain later
        uint256 DPC_InUSD_price = depositorCoin.totalSupply()/ surplusInUDS; 

        uint256 mintDepositorCoinAmount = msg.value * ethUSDprice * DPC_InUSD_price;
        /* SOMEONE deposits 1 eth as collateral; so first ETH is converted to USD
        and then that amount of usd is converted into depositor coin,
        basically calculating how much of that deposited eth is worth in USD
        
        deposit 1 eth --> 1e18 * 2000 * 0.5e18 --> GET 1000e18 DPC 
        
        */

        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }


    function withdrawCollateralBuffer( uint256 burn_depositorCoinAmount) external{
        depositorCoin.burn(msg.sender, burn_depositorCoinAmount);
        uint256 ethUSDprice=2000;

        uint256 surplusInUDS = 500; //explain later
        uint256 DPC_InUSD_price = depositorCoin.totalSupply()/ surplusInUDS; 

        /* now they want to  withdraw 1 eth as collateral; so first thier depositor Coin is converted to USD
        and then that amount of usd is converted into ether amount
      
        
        withdraw 1000 DPC --> 1000E18 * 0.5 --> 500E18 -> 500/2000 -> 0.25 ETH
      
        */
        
        uint refundAmountInUSD = burn_depositorCoinAmount * DPC_InUSD_price;
        uint refundAmountInETH = refundAmountInUSD / ethUSDprice;

        (bool success,) = msg.sender.call{value:refundAmountInETH}("");

        require(success,"STC : Withdraw collateral Coin transaction failed");
    }

} 