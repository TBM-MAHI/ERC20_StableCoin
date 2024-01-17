import {HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers"
import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import { yellow, blue, red, bgBlue,green } from "colors";
import { ERC20Mock } from "../typechain-types";
import { ethers, network } from "hardhat";
import { expect } from "chai";

//converts amount of Ether to the smaller decimal places; as defined in the 2nd Arg;
let convertToWei = (value: number) => {
  //converts 1 eth to 18 decimal places
  let res: BigInt = ethers.parseUnits(value.toString(), 18);
 //   console.log("converted to wei-", res);
    return res.toString();
};

let convertToEther = (value: BigInt) => {
  //converts 1 wei
  let res: BigInt = ethers.parseUnits(value.toString(), 1);
 //   console.log("converted to wei-", res);
    return res.toString();
};


describe("ERC20", () => {
  let signersArray: HardhatEthersSigner[],
    owner: HardhatEthersSigner,
    address_1: HardhatEthersSigner,
    amount: string;
  let ERC20TokenMock: ERC20Mock;

  let setAddress_AND_DeployERC20 = async () => {
    signersArray = await ethers.getSigners();
    owner = signersArray[0];
    address_1 = signersArray[1];

    const ERC20Token_Instance = await ethers.getContractFactory("ERC20Mock");
    ERC20TokenMock = await ERC20Token_Instance.deploy(
      "MAHI",
      "MH"
    );
    amount = convertToWei(50); // string type
    
    return { owner, address_1, amount, ERC20TokenMock };
  }

  it(green(`should success transferring the tokens`), async () => {
    //https://hardhat.org/hardhat-network-helpers/docs/reference#fixtures
    let { owner, address_1, amount, ERC20TokenMock } =
      await loadFixture(setAddress_AND_DeployERC20);
  

    await ERC20TokenMock.minNewToken(owner.address, amount);

    let sender_Balance: BigInt = await ERC20TokenMock.balanceOf(owner.address);
    console.log(
      bgBlue("Before Transfer - sender_Balance "),
      convertToEther(sender_Balance)
    );

    //await ERC20TokenMock.transfer(address_1, convertToWei(2));
    //await network.provider.send("evm_mine");

    /*
      as changeTokenBalances is chained with [*await* expect (..).to.be.changeTokenBalance() ]
      the **expect** needs to be await 
      the balance is NOT the New balance the CHANGED BALANCE/How much {debited and credited}
    */

    //owner sending to address 1
    await expect(
      await ERC20TokenMock.transfer(address_1.address, convertToWei(2))
    ).to.be.changeTokenBalances(
      ERC20TokenMock,
      [owner.address, address_1.address],
      [-2020000000000000000n, 2000000000000000000n]
    );

    //address 1 sending back to owner
    await expect(
      await ERC20TokenMock.connect(signersArray[1]).transfer(
        owner.address,
        convertToWei(1)
      )
    ).to.be.changeTokenBalances(
      ERC20TokenMock,
      [owner.address, address_1.address],
      [convertToWei(1), -1010000000000000000n]
    );

    let receiver_Balance: BigInt = await ERC20TokenMock.balanceOf(
      address_1.address
    );
    sender_Balance = await ERC20TokenMock.balanceOf(owner.address);
     console.log(
      bgBlue("After Transfer, sender_Balance"),
      convertToEther(sender_Balance)
    );
    console.log(bgBlue("receiver_Balance"), convertToEther(receiver_Balance));

    /*     expect(sender_Balance).to.be.equal(47980000000000000000n);
        expect(receiver_Balance).to.be.equal(2000000000000000000n); */
  });

  
  
  
  

  it(red("Should fail when sender has insufficient Balance"), async () => {
    let { owner, address_1, amount, ERC20TokenMock } = await loadFixture(
      setAddress_AND_DeployERC20
    );
     
    await ERC20TokenMock.minNewToken(owner.address, amount);

    let sender_Balance = await ERC20TokenMock.balanceOf(owner.address);
    console.log("Before Transfer", sender_Balance);
    
    await expect(
      ERC20TokenMock.transfer(address_1.address, convertToWei(51))
    ).to.be.revertedWith("ERC20: INSUFFCIENT SENDER BALANCE");

  });



  it(blue("Should emit Transfer Event"), async () => {
    let { owner, address_1, amount, ERC20TokenMock } = await loadFixture(
      setAddress_AND_DeployERC20
    );
    await ERC20TokenMock.minNewToken(owner.address, amount);

    await expect(
      ERC20TokenMock.connect(owner).transfer(address_1.address, convertToWei(2))
    )
      .to.emit(ERC20TokenMock, "Transfer")
      .withArgs(owner.address, address_1.address, convertToWei(2));
  });

});




