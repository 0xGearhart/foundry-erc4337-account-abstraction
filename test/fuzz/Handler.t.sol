// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {BasicAccount} from "../../src/BasicAccount.sol";
// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SendPackedUserOp} from "../../script/SendPackedUserOp.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract Handler is Test {
    BasicAccount basicAccount;
    address entryPoint;

    constructor(BasicAccount _basicAccount, address _entryPoint) {
        basicAccount = _basicAccount;
        entryPoint = _entryPoint;
    }
}
