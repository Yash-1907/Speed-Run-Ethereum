// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    address public immutable i_owner;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        i_owner = msg.sender;
    }

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 0.0001 ether;
    uint256 public deadline = block.timestamp + 100 hours;
    bool public executeCalled = false;
    bool public openForWithdraw = false;
    address[] public stakers;

    event Stake(address indexed staker, uint256 amount);

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Already Completed!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not the owner");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        stakers.push(msg.sender);
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notCompleted {
        require(timeLeft() == 0, "Wait!!");
        require(!executeCalled, "Already called!");
        if (timeLeft() == 0 && address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else if (timeLeft() == 0 && address(this).balance < threshold) {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public notCompleted {
        require(openForWithdraw, "Not open for withdrawal");
        require(balances[msg.sender] > 0, "No balance");

        uint256 bal = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: bal}("");
        require(success, "Withdrawal Failed!");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    function withdrawStake() public onlyOwner notCompleted {
        uint noOfStakers = stakers.length;
        for (uint i = 0; i < noOfStakers; i++) {
            uint bal = balances[stakers[i]];
            balances[stakers[i]] = 0;
            (bool success, ) = stakers[i].call{value: bal}("");
            require(success, "Withdrawal Failed!");
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
