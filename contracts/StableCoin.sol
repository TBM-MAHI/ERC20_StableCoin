//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {EthUSDPrice} from "./Eth_USDPrice.sol";


contract StableCoin is ERC20 {
    //Stablecoin is the Owner of the Depositor Coin
    //depositor coin contract only becomes useful when people starts deposit extra ETh (leveraged trading)
    DepositorCoin depositorCoin;
    EthUSDPrice public eth_usd_price;

     constructor 
     ( 
        string memory _name,
        string memory _symbol,
        EthUSDPrice eth_usd_price_contractAddress //address of the contract
     ) ERC20(_name,_symbol){
        eth_usd_price = eth_usd_price_contractAddress;
     }

    function mint() external payable{
       
        uint stableCoinAmount = msg.value*eth_usd_price.getPrice();;
        _mint(msg.sender, stableCoinAmount);
    }

    function burn(uint burnAmount) external {
        //REFUNDING DEPOSITED ETH
        uint refund_ETH = burnAmount/eth_usd_price.getPrice();
        /*example:
            1 deposited 1.3 eth = 1300 stablecoin 
            now refund_ETH = 1300000000000000000*1000/1000
            burn 1000 stable token and give back 1300000000000000000 wei/ 1.3eth
         */
        _burn(msg.sender, burnAmount);
        (bool success, ) = msg.sender.call{ value:refund_ETH }("");
        require(success); //      require(success==true);
    }
    //the function where extra ETH are deposited
    function depositCollateralBuffer() payable external{
        /* in Our Example :
         Total Depositor Coin Supply : 250
         Total Dollar : 500$
         price of 1 depositor Coin In USD = 0.5 USD 
         */
        uint256 surplusInUDS = getSurplusInUSD(); 
        uint256 DPC_InUSD_price = depositorCoin.totalSupply()/ surplusInUDS; 

        uint256 mintDepositorCoinAmount = msg.value * eth_usd_price.getPrice() * DPC_InUSD_price;
        /* SOMEONE deposits 1 eth as collateral; so first ETH is converted to USD
        and then that amount of usd is converted into depositor coin,
        basically calculating how much of that deposited eth is worth in USD
        
        deposit 1 eth --> 1e18 * 2000 * 0.5e18 --> GET 1000e18 DPC 
        
        */

        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }


    function withdrawCollateralBuffer( uint256 burn_depositorCoinAmount) external{
        depositorCoin.burn(msg.sender, burn_depositorCoinAmount);
       

        uint256 surplusInUDS = getSurplusInUSD();
        uint256 DPC_InUSD_price = depositorCoin.totalSupply()/ surplusInUDS; 

        /* now they want to  withdraw 1 eth as collateral; so first thier depositor Coin is converted to USD
        and then that amount of usd is converted into ether amount
      
        
        withdraw 1000 DPC --> 1000E18 * 0.5 --> 500E18 -> 500/2000 -> 0.25 ETH
      
        */
        
        uint refundAmountInUSD = burn_depositorCoinAmount * DPC_InUSD_price;
        uint refundAmountInETH = refundAmountInUSD / eth_usd_price.getPrice();

        (bool success,) = msg.sender.call{value:refundAmountInETH}("");

        require(success,"STC : Withdraw collateral Coin transaction failed");
    }

    function getSurplusInUSD() private returns(uint){
        uint ethContractBalanceInUSD = (address(this).balance- msg.value) * eth_usd_price.getPrice();
        //the total amount of stableCoin Tokens when Deployed
         uint totalStableCoinBalanceInUSD = totalSupply;

         //now calculate the surplus amount by subtracting total stable coin supply/amount from the Total Contract Balance 
        return ethContractBalanceInUSD - totalStableCoinBalanceInUSD;
    }
} 