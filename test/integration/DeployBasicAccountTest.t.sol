// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {DeployBasicAccount} from "../../script/DeployBasicAccount.s.sol";
import {CodeConstants, HelperConfig} from "../../script/HelperConfig.s.sol";
import {PackedUserOperation, SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {BasicAccount} from "../../src/BasicAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Test} from "forge-std/Test.sol";
import {SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract DeployBasicAccountTest is Test, CodeConstants {
    DeployBasicAccount deployer;
    HelperConfig.NetworkConfig config;
    BasicAccount basicAccount;
    address deployerAccount = vm.envAddress("DEFAULT_KEY_ADDRESS");

    uint256 ethMainnetFork;
    uint256 ethSepoliaFork;
    uint256 arbMainnetFork;
    uint256 arbSepoliaFork;

    uint256 constant MISSING_FUNDS_TEST_AMOUNT = 1e10;
    uint256 constant MINT_AMOUNT = 10e8;

    // need to test initialization of contract and state across all supported chains
    // create forks of all chains supported and verify correct deployment

    function setUp() external {}

    function testEthMainnetDeployment() public {
        // ETH mainnet fork
        ethMainnetFork = vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"));
        deployer = new DeployBasicAccount();
        (basicAccount, config) = deployer.run();
        assertEq(config.entryPoint, ETH_MAINNET_ENTRY_POINT);
        assertEq(config.usdc, ETH_MAINNET_USDC);
        assertEq(config.account, deployerAccount);
        assertEq(basicAccount.getEntryPoint(), config.entryPoint);
        assertEq(basicAccount.owner(), config.account);
    }

    function testEthSepoliaDeployment() public {
        // ETH Sepolia fork
        ethSepoliaFork = vm.createSelectFork(vm.envString("ETH_SEPOLIA_RPC_URL"));
        deployer = new DeployBasicAccount();
        (basicAccount, config) = deployer.run();
        assertEq(config.entryPoint, ETH_SEPOLIA_ENTRY_POINT);
        assertEq(config.usdc, ETH_SEPOLIA_USDC);
        assertEq(config.account, deployerAccount);
        assertEq(basicAccount.getEntryPoint(), config.entryPoint);
        assertEq(basicAccount.owner(), config.account);
    }

    function testArbMainnetDeployment() public {
        // ARB mainnet fork
        arbMainnetFork = vm.createSelectFork(vm.envString("ARB_MAINNET_RPC_URL"));
        deployer = new DeployBasicAccount();
        (basicAccount, config) = deployer.run();
        assertEq(config.entryPoint, ARB_MAINNET_ENTRY_POINT);
        assertEq(config.usdc, ARB_MAINNET_USDC);
        assertEq(config.account, deployerAccount);
        assertEq(basicAccount.getEntryPoint(), config.entryPoint);
        assertEq(basicAccount.owner(), config.account);
    }

    function testArbSepoliaDeployment() public {
        // ARB Sepolia fork
        arbSepoliaFork = vm.createSelectFork(vm.envString("ARB_SEPOLIA_RPC_URL"));
        deployer = new DeployBasicAccount();
        (basicAccount, config) = deployer.run();

        assertEq(config.entryPoint, ARB_SEPOLIA_ENTRY_POINT);
        assertEq(config.usdc, ARB_SEPOLIA_USDC);
        assertEq(config.account, deployerAccount);
        assertEq(basicAccount.getEntryPoint(), config.entryPoint);
        assertEq(basicAccount.owner(), config.account);

        // Neither of these attempts below work in forked testing environment
        // Seems foundry does not have access to encrypted private keys when running scripts on a fork
        // Both approaches trigger "no wallet available" errors and reverts when signing
        // Scripts and signature work fine on testnet

        // SendPackedUserOp sendPackedUserOp = new SendPackedUserOp();
        // sendPackedUserOp.run();

        // // Also test validation and signature flow from SendPackedUserOp.s.sol when not on local anvil chain
        // ERC20Mock usdc = ERC20Mock(config.usdc);
        // assertEq(usdc.balanceOf(address(basicAccount)), 0);
        // address destination = config.usdc;
        // uint256 value = 0;
        // // encode mint call from basicAccount to usdc
        // bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);
        // // encode execute call from entryPoint to basicAccount
        // bytes memory executeCallData =
        //     abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);
        // // pack encoded execute call into a PackedUserOperation struct and sign
        // PackedUserOperation memory packedUserOp =
        //     sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(basicAccount));
        // // get the hash of the packedUserOp from IEntryPoint
        // bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);
        // uint256 missingAccountFunds = MISSING_FUNDS_TEST_AMOUNT;
        // // only entry point can call validate
        // vm.prank(config.entryPoint);
        // uint256 validationData = basicAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
        // assertEq(validationData, SIG_VALIDATION_SUCCESS);
    }
}
