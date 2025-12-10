// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {BasicAccount} from "../src/BasicAccount.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
// import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {Script} from "forge-std/Script.sol";
// import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
// import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract SendPackedUserOp is Script {
    function _packUserOp(
        uint256 _nonce,
        bytes calldata _data,
        bytes32 _accountGasLimits,
        uint256 _preVerificationGas,
        bytes32 _gasFees
    )
        internal
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
        bytes memory userSig = "";
        packedUserOp = PackedUserOperation({
            sender: msg.sender, // basic account's address
            nonce: _nonce, // nonce to prevent replay attacks
            initCode: "", // ignore for deployed accounts
            callData: _data, // the operations to be executed (approve, send, etc)
            accountGasLimits: _accountGasLimits, // the amount of gas to allocate the main execution call
            preVerificationGas: _preVerificationGas, // the amount of gas to allocate for the verification step
            gasFees: _gasFees, // extra gas to pay the bundler
            paymasterAndData: "", // data for paymaster (only if paymaster exists)
            signature: userSig
        });
    }
}
