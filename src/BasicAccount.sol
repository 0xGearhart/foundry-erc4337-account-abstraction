// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/**
 * @title Basic Account Abstraction
 * @author Gearhart
 * @notice This ERC-4337 implementation only has basic functionality for example purposes
 */

contract BasicAccount is IAccount, Ownable {
    // set owner for OpenZeppelin Ownable constructor at deployment
    constructor() Ownable(msg.sender) {}

    // entrypoint will call this contract
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData)
    {
        // struct PackedUserOperation {
        //     address sender;                  // this account's address
        //     uint256 nonce;                   // nonce to prevent replay attacks
        //     bytes initCode;                  // ignore for deployed accounts
        //     bytes callData;                  // the operations to be executed (approve, send, etc)
        //     bytes32 accountGasLimits;        // the amount of gas to allocate the main execution call
        //     uint256 preVerificationGas;      // the amount of gas to allocate for the verification step
        //     bytes32 gasFees;                 // extra gas to pay the bundler
        //     bytes paymasterAndData;          // data for paymaster (only if paymaster exists)
        //     bytes signature;                 // data passed to sender to verify operation
        // }

        validationData = _validateSignature(userOp, userOpHash);

        // usually it is good practice to validate nonce as well
        // _validateNonce();

        // repay entrypoint contract
        _payPrefund(missingAccountFunds);
    }

    // A signature will be marked valid as long as it is sent by BasicAccount owner
    // This is the bare minimum for AA account and not very interesting
    // The possibilities are endless here - you can implement multisig, social recovery, 2FA, etc
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        internal
        view
        returns (uint256 validationData)
    {
        // userOpHash => EIP-191 version of the signed hash
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        // recover signer from hash
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        // verify signer is BasicAccount owner
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED; // 1
        }
        return SIG_VALIDATION_SUCCESS; // 0
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            // pay back entrypoint contract. Could hard code entrypoint contract address instead of msg.sender but this is fine
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            // entry point is responsible for ensuring transfer success so I will just leave as is to satisfy linter
            (success);
        }
    }
}
