// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/**
 * @title Basic Account Abstraction
 * @author Gearhart
 * @notice This ERC-4337 implementation only has basic functionality for example purposes
 */

contract BasicAccount is IAccount, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error BasicAccount__NotFromEntryPoint();
    error BasicAccount__NotFromEntryPointOrOwner();
    error BasicAccount__ExecutionFailed(bytes result);
    error BasicAccount__WithdrawFailed();

    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    IEntryPoint private immutable i_entryPoint;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // ensure only the entrypoint can call a function
    modifier requireFromEntryPoint() {
        _requireFromEntryPoint(msg.sender);
        _;
    }

    // ensure only entrypoint OR owner can call function
    // adds versatility so owner can call execute themselves if desired
    modifier requireFromEntryPointOrOwner() {
        _requireFromEntryPointOrOwner(msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev set owner for OpenZeppelin Ownable constructor at deployment
     * @param entryPoint address of the entryPoint contract
     */
    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    /**
     * @dev need the ability to receive so this contract can pay for transactions
     * could also use a paymaster but this basic implementation does not
     */
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Only callable from entry point contract
     * @param userOp struct containing all necessary info for validation and execution of user operations
     * @param userOpHash hash of the user operation
     * @param missingAccountFunds amount of funds to transfer to entry point to cover execution costs
     * @return validationData 0 if signature is valid, 1 if not
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);

        // usually it is good practice to validate nonce as well but entrypoint will ensure nonce uniqueness
        // _validateNonce();

        // repay entrypoint contract
        _payPrefund(missingAccountFunds);
    }

    /**
     * @notice Execute user operations after validation
     * @param destination destination address
     * @param value value to be sent
     * @param functionData ABI encoded function data
     */
    function execute(
        address destination,
        uint256 value,
        bytes calldata functionData
    )
        external
        requireFromEntryPointOrOwner
    {
        (bool success, bytes memory result) = destination.call{value: value}(functionData);
        if (!success) {
            revert BasicAccount__ExecutionFailed(result);
        }
    }

    /**
     * @notice Only owner can withdraw funds from basic account
     * @param amount amount of ETH to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        (bool success,) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert BasicAccount__WithdrawFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev A signature will be marked valid as long as it is sent by BasicAccount owner
     * This is the bare minimum for AA account
     * The possibilities are endless here - you can implement multisig, social recovery, 2FA, etc
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        internal
        view
        returns (uint256 validationData)
    {
        // userOpHash => EIP-191 version of the signed hash
        bytes32 ethSignedMessageHash = userOpHash.toEthSignedMessageHash();
        // recover signer from hash
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        // verify signer is BasicAccount owner
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED; // 1
        }
        return SIG_VALIDATION_SUCCESS; // 0
    }

    /**
     * @dev Pay back the entrypoint contract
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            // could hard code entrypoint contract address instead of msg.sender but this is fine
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            // entry point is responsible for ensuring payment is good so I will just leave as is to satisfy linter
            (success);
        }
    }

    /**
     * @dev check if sender is entrypoint
     */
    function _requireFromEntryPoint(address sender) internal view {
        if (sender != address(i_entryPoint)) {
            revert BasicAccount__NotFromEntryPoint();
        }
    }

    /**
     * @dev check if sender is entrypoint or BasicAccount owner
     */
    function _requireFromEntryPointOrOwner(address sender) internal view {
        if (sender != address(i_entryPoint) && sender != owner()) {
            revert BasicAccount__NotFromEntryPointOrOwner();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the address of the entrypoint contract
     * @return address address of the entry point
     */
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}
