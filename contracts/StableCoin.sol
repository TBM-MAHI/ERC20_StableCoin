//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";


contract StableCoin is ERC20 {
    //Stablecoin is the Owner of the Depositor Coin
    //depositor coin contract only becomes useful when people starts deposit extra ETh (leveraged trading)
    DepositorCoin depositorCoin;
    Oracle public oracle;
    uint private feePercentage = 2;
     constructor 
     ( 
        string memory _name,
        string memory _symbol,
        Oracle oracle_contractAddress //address of the contract
     ) ERC20(_name,_symbol)
     {
        oracle = oracle_contractAddress;
     }

    function mint() external payable{
        /// @dev calculate the eth USD price
        uint feeAmount = calculateFee(msg.value);
        uint stableCoinAmount = (msg.value - feeAmount)*oracle.getPrice();
        _mint(msg.sender, stableCoinAmount);
    }

    function burn(uint burnAmount) external {
        //REFUNDING DEPOSITED ETH
        uint refund_ETH = burnAmount/oracle.getPrice();
        /*example:
            1 deposited 1.3 eth = 1300 stablecoin 
            now refund_ETH = 1300000000000000000*1000/1000
            burn 1000 stable token and give back 1300000000000000000 wei/ 1.3eth
         */
        _burn(msg.sender, burnAmount);
        uint feeAmount = calculateFee(refund_ETH);
        (bool success, ) = msg.sender.call{ value:refund_ETH - feeAmount }("");
        require(success); //      require(success==true);
    }

    function calculateFee(uint amount) private returns(uint){
        return amount*(feePersentage/100);
    }

 /// @dev // the function where extra ETH are deposited by leveraged traders
    function depositCollateralBuffer() payable external{
        /* in Our Example :
         Total Depositor Coin Supply : 250
         Total Dollar : 500$
         price of 1 depositor Coin In USD = 0.5 USD 
         */
        int deficit_or_surplus  = get_Surplus__OR__DeficitInUSD();
        uint256 DPC_InUSD_price; 

        /// @dev initial the surplus amount is 0; so in the first deposit we can set the deposited 
        /// @dev eth (converted to USD) As the initial/starting surplus amount

        if( deficit_or_surplus ==0){
          //deploy the DepositorCoin now because this is when it becomes relevant
          depositorCoin = new DepositorCoin("Depositor Coin","DPC");
          //uint starting_depositorAmount= msg.value
            DPC_InUSD_price = 1;
        } 
        else{
            DPC_InUSD_price = depositorCoin.totalSupply() /  deficit_or_surplus ;
        }

       
        uint256 mintDepositorCoinAmount = msg.value * oracle.getPrice() * DPC_InUSD_price;
        /* SOMEONE deposits 1 eth as collateral; so first ETH is converted to USD
        and then that amount of usd is converted into depositor coin,
        basically calculating how much of that deposited eth is worth in USD
        
        deposit 1 eth --> 1e18 * 2000 * 0.5e18 --> GET 1000e18 DPC 
        */

        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }


    function withdrawCollateralBuffer( uint256 burn_depositorCoinAmount) external{
        depositorCoin.burn(msg.sender, burn_depositorCoinAmount);
       
        int deficit_or_surplus  = get_Surplus__OR__DeficitInUSD();
        require(deficit_or_surplus > 0, "STC: Not Enough Surplus to Withdraw");

        uint surplus = uint(deficit_or_surplus);
        uint256 DPC_InUSD_price = depositorCoin.totalSupply()/ surplus; 

        /* 
        now they want to  withdraw 1 eth as collateral; so first thier depositor Coin is converted to USD
        and then that amount of usd is converted into ether amount
        withdraw 1000 DPC --> 1000E18 * 0.5 --> 500E18 -> 500/2000 -> 0.25 ETH
        */
        
        uint refundAmountInUSD = burn_depositorCoinAmount * DPC_InUSD_price;
        uint refundAmountInETH = refundAmountInUSD / oracle.getPrice();

        (bool success,) = msg.sender.call{value:refundAmountInETH}("");

        require(success,"STC : Withdraw collateral Coin transaction failed");
    }

    function get_Surplus__OR__DeficitInUSD() private returns(int){
        uint ethContractTotalBalanceInUSD = (address(this).balance- msg.value) * oracle.getPrice();
        //the total amount of stableCoin Tokens when Deployed
         uint totalStableCoinBalanceInUSD = totalSupply;

         /// now calculate the surplus or Deficit amount(when the pool is underwater) by subtracting total stable coin supply/amount 
         /// from the Total Contract Balance 

         
         /// @notice Example 
         /// @dev Explain to a developer any extra details 
         
         int deficit_or_surplus = int( ethContractTotalBalanceInUSD )-int( totalStableCoinBalanceInUSD );
        return deficit_or_surplus;
    }
} 