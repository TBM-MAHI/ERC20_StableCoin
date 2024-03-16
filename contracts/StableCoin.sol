//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";


contract StableCoin is ERC20 {
    //Stablecoin is the Owner of the Depositor Coin
    //depositor coin contract only becomes useful when people starts deposit extra ETH (leveraged trading)
    DepositorCoin depositorCoin;
    Oracle public oracle;
    uint private feePercentage = 2;
    uint public initial_Collateral_Ratio_Percentage;
    uint public Depositor_Coin_LockTime;

    constructor 
     ( 
        string memory _name,
        string memory _symbol,
        uint _initial_Collateral_Ratio_Percentage,
        uint _locktime,
        Oracle oracle_contractAddress  // address of the contract
     ) ERC20(_name,_symbol)
     {
        initial_Collateral_Ratio_Percentage = _initial_Collateral_Ratio_Percentage;
        Depositor_Coin_LockTime = _locktime;
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

    function calculateFee(uint amount) private view returns(uint){
        return amount*(feePersentage/100);
    }

    /// @dev // the function where extra ETH are deposited by leveraged traders
    function depositCollateralBuffer() payable external{
        /* in Our Example :
         Total Depositor Coin Supply : 250
         Total Dollar : 500$
         price of 1 depositor Coin In USD/1DPC = 0.5 USD 
         */
        int deficit_or_surplus  = get_Surplus__OR__DeficitInUSD();
        uint added_surplus;
        uint256 DPC_InUSD_price; 

        /// @dev initial the surplus amount is 0; so in the first deposit we can set the deposited 
        /// @dev eth (converted to USD) As the initial/starting surplus amount

        if( deficit_or_surplus <= 0){
            ///$notice deploy the DepositorCoin in 2 Criteria 
                                        /// 1. initially when the surplus amount is Zero/empty
                                        /// 2. When the pool is underwater or negative surplus 
            ///DEPLOYING WILL RESET THE TOTAL SUPPLY TO 0
            uint required_minimum_surplus_In_USD= ( initial_Collateral_Ratio_Percentage/100) * totalSupply ;
            
            // Safety Margin : 25% --> ( 25/100 * 1000) = 250 USD is the Safety Margin
            uint required_minimum_surplus_In_ETH= required_minimum_surplus_In_USD / oracle.getPrice();
            
            uint deficit_USD = uint(deficit_or_surplus * -1);
            uint deficit_ETH = deficit_USD / oracle.getPrice();     
            added_surplus = msg.value - deficit_ETH; //adjusting the surplus by subtracting deficit
            
            require(added_surplus >= required_minimum_surplus_In_ETH, "STC : Initial Collateral ratio Not Met");
            depositorCoin = new DepositorCoin("Depositor Coin", "DPC", Depositor_Coin_LockTime);
            //uint starting_depositorAmount = msg.value
            DPC_InUSD_price = 1;
        } 
        else{
            uint surplus = uint(deficit_or_surplus);
            DPC_InUSD_price = depositorCoin.totalSupply() / surplus ;
            added_surplus = msg.value;
        }

        uint256 mintDepositorCoinAmount = added_surplus * oracle.getPrice() * DPC_InUSD_price;
        /* 
            SOMEONE deposits 1 eth as collateral; so first ETH is converted to USD
            and then that amount of usd is converted into depositor coin,
            basically calculating how much of that deposited eth is worth in USD
         */   
          /// @dev deposit 1 eth --> 1e18 * 2000 * 0.5e18 --> GET 1000e18 DPC 
        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }


    function withdrawCollateralBuffer( uint256 burn_depositorCoinAmount) external{
        depositorCoin.burn(msg.sender, burn_depositorCoinAmount);
       
        int deficit_or_surplus  = get_Surplus__OR__DeficitInUSD();
        require(deficit_or_surplus > 0, "STC: Not Enough Surplus to Withdraw");
        /// As surplus is >0 ; so there is DPC in the pool; so extra ether depositors can withdraw
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

         /// now calculate the surplus or Deficit amount(Deficit-->when the pool is underwater) by subtracting total stable coin supply/amount 
         /// from the Total Contract Balance 

         
         /// @notice Example of deficit :::::
         /// Deficit amount:  pool total balance(1500$) - Stable coin balance(2000 Stable Coin-2000$) = -500$
         
        int deficit_or_surplus = int( ethContractTotalBalanceInUSD )-int( totalStableCoinBalanceInUSD );
        return deficit_or_surplus;
    }
} 