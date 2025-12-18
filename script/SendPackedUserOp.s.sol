// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {BasicAccount} from "../src/BasicAccount.sol";
import {CodeConstants, HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Script} from "forge-std/Script.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract SendPackedUserOp is Script, CodeConstants {
    using MessageHashUtils for bytes32;

    // Make sure you trust this address - don't run this on Mainnet! Only for testing and example purposes.
    address addressToApprove = vm.envAddress("SECONDARY_ADDRESS");

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address deployedBasicAccountAddress = DevOpsTools.get_most_recent_deployment("BasicAccount", block.chainid);
        address destination = config.usdc;
        uint256 value = 0;
        uint256 amountToApprove = 1e6; // 1 usdc since usdc has 6 decimals (mock has 18 decimals but still good in case script is ran on mainnet accidentally)
        bytes memory functionData = abi.encodeWithSelector(IERC20.approve.selector, addressToApprove, amountToApprove);
        bytes memory executeCallData =
            abi.encodeWithSelector(BasicAccount.execute.selector, destination, value, functionData);
        PackedUserOperation memory userOp =
            generateSignedUserOperation(executeCallData, config, deployedBasicAccountAddress);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast();
        IEntryPoint(config.entryPoint).handleOps(ops, payable(config.account));
        vm.stopBroadcast();
    }

    function generateSignedUserOperation(
        bytes memory _callData,
        HelperConfig.NetworkConfig memory config,
        address basicAccount
    )
        public
        view
        returns (PackedUserOperation memory)
    {
        // get nonce from sender and decrement by 1 to get correct nonce
        uint256 nonce = vm.getNonce(basicAccount) - 1;
        // generate unsigned user operation struct with basicAccount contract as sender and config.account as signer
        PackedUserOperation memory userOperation = generateUnsignedUserOperation(basicAccount, nonce, _callData);

        // get the user operation hash (userOpHash) from entry point to ensure correctness
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOperation);
        // format the hash before signing
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // sign user operation
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == LOCAL_CHAIN_ID) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        // add signature to userOperation to complete struct
        userOperation.signature = abi.encodePacked(r, s, v); // make sure correct order is used
        // return completed and signed PackedUserOperation
        return userOperation;
    }

    function generateUnsignedUserOperation(
        address _sender,
        uint256 _nonce,
        bytes memory _callData
    )
        public
        pure
        returns (PackedUserOperation memory packedUserOp)
    {
        // struct PackedUserOperation {
        //     address sender;                  // basic account's address
        //     uint256 nonce;                   // nonce to prevent replay attacks
        //     bytes initCode;                  // ignore for deployed accounts
        //     bytes callData;                  // the operations to be executed (approve, send, etc)
        //     bytes32 accountGasLimits;        // the amount of gas to allocate the main execution call
        //     uint256 preVerificationGas;      // the amount of gas to allocate for the verification step
        //     bytes32 gasFees;                 // extra gas to pay the bundler
        //     bytes paymasterAndData;          // data for paymaster (only if paymaster exists)
        //     bytes signature;                 // data passed to sender to verify operation
        // }
        uint128 verificationGasLimit = 16_777_216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        packedUserOp = PackedUserOperation({
            sender: _sender, // basic account's address
            nonce: _nonce, // nonce to prevent replay attacks
            initCode: hex"", // ignore for deployed accounts
            callData: _callData, // the operations to be executed (approve, send, etc)
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit), // the amount of gas to allocate the main execution call
            preVerificationGas: verificationGasLimit, // the amount of gas to allocate for the verification step
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas), // extra gas to pay the bundler
            paymasterAndData: hex"", // data for paymaster (only if paymaster exists)
            signature: hex""
        });
    }
}
