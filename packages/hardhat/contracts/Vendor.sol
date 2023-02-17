pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

error Vendor__NotEnoughEth();
error Vendor__NotEnoughTokens();
error Vendor__TransactionFailed();
error Vendor__NotEnoughTokens2();

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    YourToken public yourToken;

    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        uint amtInEth = msg.value;
        if (amtInEth <= 0) {
            revert Vendor__NotEnoughEth();
        }
        uint amtOfTokens = amtInEth * tokensPerEth;

        if (amtOfTokens > yourToken.balanceOf(address(this))) {
            revert Vendor__NotEnoughTokens();
        }

        bool success = yourToken.transfer(msg.sender, amtOfTokens);
        if (!success) {
            revert Vendor__TransactionFailed();
        }

        emit BuyTokens(msg.sender, amtInEth, amtOfTokens);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public onlyOwner {
        uint vendorBalance = address(this).balance;
        if (vendorBalance <= 0) {
            revert Vendor__NotEnoughEth();
        }
        address owner = msg.sender;
        (bool success, ) = owner.call{value: vendorBalance}("");
        if (!success) {
            revert Vendor__TransactionFailed();
        }
    }

    // ToDo: create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 _amount) public {
        if (_amount <= 0) {
            revert Vendor__NotEnoughTokens();
        }
        address seller = msg.sender;
        if (yourToken.balanceOf(seller) < _amount) {
            revert Vendor__NotEnoughTokens2();
        }

        uint amtInEth = _amount / tokensPerEth;
        if (amtInEth > address(this).balance) {
            revert Vendor__NotEnoughEth();
        }

        bool success = yourToken.transferFrom(seller, address(this), _amount);
        if (!success) {
            revert Vendor__TransactionFailed();
        }

        (bool success2, ) = seller.call{value: amtInEth}("");
        if (!success2) {
            revert Vendor__TransactionFailed();
        }
    }
}
