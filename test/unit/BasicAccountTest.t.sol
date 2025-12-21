// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {DeployBasicAccount} from "../../script/DeployBasicAccount.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {PackedUserOperation, SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {BasicAccount, Ownable} from "../../src/BasicAccount.sol";
import {InvalidReceiver} from "../mocks/InvalidReceiver.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Test} from "forge-std/Test.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract BasicAccountTest is Test {
    using MessageHashUtils for bytes32;

    DeployBasicAccount deployer;
    HelperConfig.NetworkConfig config;
    BasicAccount basicAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    uint256 constant MINT_AMOUNT = 10e8; // 100 usdc since usdc has 6 decimals. Mock has 18 decimals but still good to be consistent
    uint256 constant BASIC_ACCOUNT_FUND_AMOUNT = 1 ether;
    uint256 constant BASIC_ACCOUNT_WITHDRAW_AMOUNT = 0.25 ether;
    uint256 constant MISSING_FUNDS_TEST_AMOUNT = 1e10;

    address constant INVALID_SIGNER_ANVIL_ADDRESS = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint256 constant INVALID_SIGNER_ANVIL_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    address randomUser = makeAddr("randomUser");

    function setUp() external {
        deployer = new DeployBasicAccount();
        (basicAccount, config) = deployer.run();
        usdc = ERC20Mock(config.usdc);
        sendPackedUserOp = new SendPackedUserOp();
    }

    /*//////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    function testBasicAccountCanReceiveEther() public {
        assertEq(address(basicAccount).balance, 0);
        vm.deal(randomUser, BASIC_ACCOUNT_FUND_AMOUNT);
        vm.prank(randomUser);
        (bool success,) = address(basicAccount).call{value: BASIC_ACCOUNT_FUND_AMOUNT}("");
        assert(success);
        assertEq(address(basicAccount).balance, BASIC_ACCOUNT_FUND_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testNonOwnerCanNotWithdrawEther() public {
        vm.deal(address(basicAccount), BASIC_ACCOUNT_FUND_AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, randomUser));
        vm.prank(randomUser);
        basicAccount.withdraw(type(uint256).max);
    }

    function testWithdrawFailsIfCallIsUnsuccessful() public {
        InvalidReceiver invalidReceiver = new InvalidReceiver();
        vm.prank(basicAccount.owner());
        basicAccount.transferOwnership(address(invalidReceiver));
        vm.deal(address(basicAccount), BASIC_ACCOUNT_FUND_AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(BasicAccount.BasicAccount__WithdrawFailed.selector));
        vm.prank(address(invalidReceiver));
        basicAccount.withdraw(type(uint256).max);
    }

    function testOwnerCanWithdrawEther() public {
        assertEq(basicAccount.owner().balance, 0);
        assertEq(address(basicAccount).balance, 0);
        vm.deal(address(basicAccount), BASIC_ACCOUNT_FUND_AMOUNT);
        assertEq(address(basicAccount).balance, BASIC_ACCOUNT_FUND_AMOUNT);
        vm.prank(basicAccount.owner());
        basicAccount.withdraw(type(uint256).max);
        assertEq(basicAccount.owner().balance, BASIC_ACCOUNT_FUND_AMOUNT);
        assertEq(address(basicAccount).balance, 0);
    }

    function testOwnerCanPartiallyWithdrawEther() public {
        assertEq(basicAccount.owner().balance, 0);
        assertEq(address(basicAccount).balance, 0);
        vm.deal(address(basicAccount), BASIC_ACCOUNT_FUND_AMOUNT);
        assertEq(address(basicAccount).balance, BASIC_ACCOUNT_FUND_AMOUNT);
        vm.prank(basicAccount.owner());
        basicAccount.withdraw(BASIC_ACCOUNT_WITHDRAW_AMOUNT);
        assertEq(basicAccount.owner().balance, BASIC_ACCOUNT_WITHDRAW_AMOUNT);
        assertEq(address(basicAccount).balance, BASIC_ACCOUNT_FUND_AMOUNT - BASIC_ACCOUNT_WITHDRAW_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                                EXECUTE
    //////////////////////////////////////////////////////////////*/

    function testNonOwnerCanNotExecuteCommands() public {
        // arrange
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);

        // act & assert
        vm.prank(randomUser);
        vm.expectRevert(BasicAccount.BasicAccount__NotFromEntryPointOrOwner.selector);
        basicAccount.execute(destination, value, functionData);
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
    }

    function testExecutionFailsIfFunctionDataIsInvalid() public {
        // arrange
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        // should fail since basicAccount does not have any tokens to burn
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.burn.selector, address(basicAccount), MINT_AMOUNT);

        // ACT & ASSERT
        vm.prank(basicAccount.owner());
        vm.expectPartialRevert(BasicAccount.BasicAccount__ExecutionFailed.selector);
        basicAccount.execute(destination, value, functionData);
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
    }

    function testOwnerCanExecuteCommands() public {
        // arrange
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);

        // act
        vm.prank(basicAccount.owner());
        basicAccount.execute(destination, value, functionData);

        // assert
        assertEq(usdc.balanceOf(address(basicAccount)), MINT_AMOUNT);
    }

    function testEntryPointCanExecuteCommands() public {
        // ARRANGE
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        // encode mint call from basicAccount to usdc
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);
        // encode execute call from entryPoint to basicAccount
        bytes memory executeCallData =
            abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);
        // pack encoded execute call into a PackedUserOperation struct and sign
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(basicAccount));

        vm.deal(address(basicAccount), BASIC_ACCOUNT_FUND_AMOUNT);
        // entry point contract expects an array of PackedUserOperation structs when calling handelOps so create that here
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        // add our PackedUserOperation struct to the array
        ops[0] = packedUserOp;

        // ACT
        vm.prank(randomUser, randomUser);
        // send array of user operations and the address of the one executing the transaction on our behalf so they can be reimbursed
        IEntryPoint(config.entryPoint).handleOps(ops, payable(randomUser));

        // ASSERT
        assertEq(usdc.balanceOf(address(basicAccount)), MINT_AMOUNT);
    }

    // TODO
    // function testEntryPointIsNotPaidBackGasAfterExecutionIfMissingAccountFundsIsZero() public {}

    //TODO
    // function testEntryPointIsPaidBackGasAfterExecution() public {}

    /*//////////////////////////////////////////////////////////////
                            VALIDATE USER OP
    //////////////////////////////////////////////////////////////*/

    function testRecoverSignedOperation() public view {
        // ARRANGE
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        // encode mint call from basicAccount to usdc
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);
        // encode execute call from entryPoint to basicAccount
        bytes memory executeCallData =
            abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);
        // pack encoded execute call into a PackedUserOperation struct and sign
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(basicAccount));
        // get the hash of the packedUserOp from IEntryPoint
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);

        // ACT
        (address actualSigner,,) = ECDSA.tryRecover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        // ASSERT
        assertEq(actualSigner, basicAccount.owner());
    }

    function testValidationOfUserOperationsFailsWhenSignerIsNotOwner() external {
        // ARRANGE
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        // encode mint call from basicAccount to usdc
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);
        // encode execute call from entryPoint to basicAccount
        bytes memory executeCallData =
            abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);

        // NEED TO PACK OUR OWN USER OP TO FILL & SIGN WITH INVALID SIGNATURE FROM NON OWNER
        // pack encoded execute call into a PackedUserOperation struct and sign
        // get nonce from sender and decrement by 1 to get correct nonce
        uint256 nonce = vm.getNonce(address(basicAccount)) - 1;
        // generate unsigned user operation struct with basicAccount contract as sender and config.account as signer
        PackedUserOperation memory userOperation =
            sendPackedUserOp.generateUnsignedUserOperation(address(basicAccount), nonce, executeCallData);
        // get the user operation hash (userOpHash) from entry point to ensure correctness
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOperation);
        // format the hash before signing
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // change signature value in struct to an invalid signature from a user who is not the owner
        // sign user operation
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(INVALID_SIGNER_ANVIL_KEY, digest);
        // add invalid signature to userOperation to complete struct
        userOperation.signature = abi.encodePacked(r, s, v);

        // get the hash of the userOperation from IEntryPoint
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(userOperation);
        uint256 missingAccountFunds = MISSING_FUNDS_TEST_AMOUNT;

        // ACT
        // only entry point can call validate
        vm.prank(config.entryPoint);
        uint256 validationData = basicAccount.validateUserOp(userOperation, userOperationHash, missingAccountFunds);

        // ASSERT
        assertEq(validationData, SIG_VALIDATION_FAILED);
    }

    function testValidationOfUserOperationsFailsIfNotCalledByEntryPoint() public {
        // ARRANGE
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        // encode mint call from basicAccount to usdc
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);
        // encode execute call from entryPoint to basicAccount
        bytes memory executeCallData =
            abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);
        // pack encoded execute call into a PackedUserOperation struct and sign
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(basicAccount));
        // get the hash of the packedUserOp from IEntryPoint
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = MISSING_FUNDS_TEST_AMOUNT;

        // ACT
        // only entry point can call validate, even if operation is valid
        vm.prank(randomUser);
        vm.expectRevert(abi.encodeWithSelector(BasicAccount.BasicAccount__NotFromEntryPoint.selector));
        basicAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
    }

    function testValidationOfUserOperations() public {
        // ARRANGE
        assertEq(usdc.balanceOf(address(basicAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        // encode mint call from basicAccount to usdc
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(basicAccount), MINT_AMOUNT);
        // encode execute call from entryPoint to basicAccount
        bytes memory executeCallData =
            abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);
        // pack encoded execute call into a PackedUserOperation struct and sign
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateSignedUserOperation(executeCallData, config, address(basicAccount));
        // get the hash of the packedUserOp from IEntryPoint
        bytes32 userOperationHash = IEntryPoint(config.entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = MISSING_FUNDS_TEST_AMOUNT;

        // ACT
        // only entry point can call validate
        vm.prank(config.entryPoint);
        uint256 validationData = basicAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);

        // ASSERT
        assertEq(validationData, SIG_VALIDATION_SUCCESS);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function testGetEntryPoint() external view {
        assertEq(basicAccount.getEntryPoint(), config.entryPoint);
    }

    function testOwnerIsSetCorrectly() external view {
        assertEq(basicAccount.owner(), config.account);
    }
}
