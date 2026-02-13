// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundME is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function fundFundME(address mostRecnetlyDeployed) public {
        FundMe(payable(mostRecnetlyDeployed)).fund{value: SEND_VALUE}();

        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecnetlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        FundFundME(mostRecnetlyDeployed);
        vm.stopBroadcast();
    }
}

contract WithdrawFundME is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function withdrawFundME(address mostRecnetlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecnetlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdrew from FundMe");
    }

    function run() external {
        address mostRecnetlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        WithdrawFundME(mostRecnetlyDeployed);
        vm.stopBroadcast();
    }
}
