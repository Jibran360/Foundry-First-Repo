// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {MockV3Aggregator} from "../../test/mocks/MockV3Aggregator.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    receive() external payable {}

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether; // 10000000000000000

    uint256 STARTING_BALANCE = 10 ether;

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 2000e8;

    //uint256 constant GAS_PRICE = 1;

    function setUp() external {
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );

        fundMe = new FundMe(address(mockPriceFeed));
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line of code should revert, if it doesn't the test will fail
        fundMe.fund(); // sending 0 vlaue
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.deal(USER, SEND_VALUE);
        vm.prank(USER); // the next line of code will be sent from USER address
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.deal(USER, SEND_VALUE);
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.deal(USER, SEND_VALUE);
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        //uint256 gasstart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasstart - gasEnd) * tx.gasprice;
        //console.log("Gas Used:", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we start from 1 because 0 is the default value of an address, and we want to avoid that

        uint256 originalFundMeBalance = address(fundMe).balance; // This is for people running forked tests!

        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundedeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundedeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );

        uint256 expectedTotalValueWithdrawn = ((numberOfFunders) * SEND_VALUE) +
            originalFundMeBalance;
        uint256 totalValueWithdrawn = fundMe.getOwner().balance -
            startingOwnerBalance;

        assert(expectedTotalValueWithdrawn == totalValueWithdrawn);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // we start from 1 because 0 is the default value of an address, and we want to avoid that

        uint256 originalFundMeBalance = address(fundMe).balance; // This is for people running forked tests!

        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundedeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundedeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );

        uint256 expectedTotalValueWithdrawn = ((numberOfFunders) * SEND_VALUE) +
            originalFundMeBalance;
        uint256 totalValueWithdrawn = fundMe.getOwner().balance -
            startingOwnerBalance;

        assert(expectedTotalValueWithdrawn == totalValueWithdrawn);
    }
}
