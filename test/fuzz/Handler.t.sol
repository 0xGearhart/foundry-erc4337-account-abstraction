// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {BasicAccount} from "../../src/BasicAccount.sol";
import {Test, console} from "forge-std/Test.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract Handler is Test {
    BasicAccount basicAccount;
    SendPackedUserOp sendPackedUserOp;
    HelperConfig.NetworkConfig config;

    constructor(BasicAccount _basicAccount, HelperConfig.NetworkConfig memory _config) {
        sendPackedUserOp = new SendPackedUserOp();
        basicAccount = _basicAccount;
        config = _config;
    }

    function execute(address destination, uint256 value, bytes calldata functionData) external {
        vm.prank(msg.sender);
        vm.expectRevert(BasicAccount.BasicAccount__NotFromEntryPointOrOwner.selector);
        basicAccount.execute(destination, value, functionData);
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
    {
        vm.prank(msg.sender);
        vm.expectRevert(BasicAccount.BasicAccount__NotFromEntryPoint.selector);
        basicAccount.validateUserOp(userOp, userOpHash, missingAccountFunds);
    }

    // function _packUserOperation() internal {
    // }
}
