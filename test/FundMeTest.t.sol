//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    FundMe fundme;

    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinumumUSD() external view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgender() external view {
        assertEq(fundme.i_owner(), msg.sender);
    }

    function testPriceFeedVersion() external view {
        uint256 value = fundme.getVersion();
        assertEq(value, 4);
    }

    function testFundmeFailWirhoutMinUSD() external {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundsUpdateDataStructure() external funded {
        // vm.prank(USER);
        // fundme.fund{value: SEND_VALUE}();
        assertEq(fundme.getAddressToAmountFunded(USER), SEND_VALUE);
        assertEq(fundme.getFunder(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerModifier() external funded{
        // vm.prank(USER);
        // fundme.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundme.withdraw();
    }

    function testWithdrawWithSingleFunder() external funded {
        //arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        //act
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        //assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunder() external funded {
        //arrange
        uint160 startingIndex = 1;
        uint160 numberOfFunders = 10;
        for(uint160 i = startingIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundme.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        //Act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        //assert
        assertEq(address(fundme).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundme.getOwner().balance);      

    }
}
