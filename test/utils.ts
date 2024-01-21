import { ethers, network } from "hardhat";


//converts amount of Ether to the smaller decimal places; as defined i the 2nd Arg;
let convertToWei = (value: number) => {
    //THEY DO EXACTLY THE SAME 
    //parsing units meaning it's  going to parse/convert the value from ether to the smallest unit
  let res: BigInt = ethers.parseUnits(value.toString(), "ether");
  //let res: BigInt = ethers.parseUnits(value.toString(), 18);
  console.log("converted to wei-", res);
  return res.toString();
};

let amount: string = convertToWei(1);

console.log(typeof amount);