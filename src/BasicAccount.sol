// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/** 
 * @title Basic Account Abstraction
 * @author Gearhart
 * @notice This implementation only has basic functionality
 */

contract BasicAccount is IAccount {
    // entrypoint will call this to validate user operation
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData){

    };
}
