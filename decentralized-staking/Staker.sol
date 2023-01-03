// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

error Staker__completed();
error Staker__deadlineNotPassed();
error Staker__deadlinePassed();
error Staker__thresholdMet();

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    // Events
    event Stake(address indexed, uint256);

    // Modifiers
    modifier notCompleted() {
        if (exampleExternalContract.completed()) {
            revert Staker__completed();
        }
        _;
    }

    modifier deadlinePassed() {
        if (timeLeft() != 0) {
            revert Staker__deadlineNotPassed();
        }
        _;
    }

    modifier notPassDeadline() {
        if (timeLeft() == 0) {
            revert Staker__deadlinePassed();
        }
        _;
    }

    modifier thresholdNotMet() {
        if (address(this).balance >= threshold) {
            revert Staker__thresholdMet();
        }
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        if (timeLeft() == 0) {
            revert Staker__deadlinePassed();
        }
        stake();
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable notPassDeadline {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() external notCompleted {
        bool isPassDeadline = bool(timeLeft() == 0);
        if (address(this).balance >= threshold && isPassDeadline) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() external deadlinePassed notCompleted thresholdNotMet {
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No Balances");
        balances[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: userBalance}("");
        require(sent, "Failed to withdraw");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (deadline <= block.timestamp) {
            return 0;
        }
        return deadline - block.timestamp;
    }

}
