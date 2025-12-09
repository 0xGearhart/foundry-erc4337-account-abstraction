// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {DeployBasicAccount} from "../../script/DeployBasicAccount.s.sol";
import {BasicAccount} from "../../src/BasicAccount.sol";
import {Handler} from "./Handler.t.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployBasicAccount public deployer;
    Handler public handler;
    BasicAccount basicAccount;
    address entryPoint;

    function setUp() external {
        deployer = new DeployBasicAccount();
        (basicAccount, entryPoint) = deployer.run();
        handler = new Handler(basicAccount, entryPoint);

        targetContract(address(handler));
    }

    function invariant_gettersShouldNeverRevert() public view {
        // Basic Account getters
        basicAccount.getEntryPoint();
    }
}
