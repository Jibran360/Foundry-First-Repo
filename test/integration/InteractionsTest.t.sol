// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundME, WithdrawFundME} from "../../script/Interactions.s.sol";

contract IntegrationsTest is Test {
    FundMe fundMe;

    receive() external payable {}

    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether; // 10000000000000000

    uint256 STARTING_BALANCE = 10 ether;

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 2000e8;

    function setUp() external {
        // we want to use the real price feed contract on Sepolia, so we don't need to do anything here
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, ) = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() public {
        FundFundME fundFundMe = new FundFundME();
        vm.deal(address(fundFundMe), 1 ether);
        fundFundMe.fundFundME(address(fundMe));

        WithdrawFundME withdrawFundMe = new WithdrawFundME();
        withdrawFundMe.withdrawFundME(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
