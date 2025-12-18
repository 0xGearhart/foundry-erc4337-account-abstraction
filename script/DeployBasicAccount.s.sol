// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {BasicAccount} from "../src/BasicAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";

contract DeployBasicAccount is Script {
    function run() external returns (BasicAccount basicAccount, HelperConfig.NetworkConfig memory config) {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        basicAccount = new BasicAccount(config.entryPoint);
        vm.stopBroadcast();
    }
}
