// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidNetwork(uint256 chainId);

    uint256 public constant LOCAL_CHAIN_ID = 31_337;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;

    address public constant ETH_MAINNET_ENTRY_POINT = address(0);
    address public constant ETH_SEPOLIA_ENTRY_POINT = address(0);

    function run() external view returns (address entryPoint, address sender) {
        if (block.chainid == ETH_MAINNET_CHAIN_ID) {
            return _getEthMainnetConfig();
        } else if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            return _getEthSepoliaConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            return _getOrCreateLocalConfig();
        } else {
            revert HelperConfig__InvalidNetwork(block.chainid);
        }
    }

    function _getEthMainnetConfig() internal view returns (address entryPoint, address sender) {
        entryPoint = ETH_MAINNET_ENTRY_POINT;
        sender = vm.envAddress("DEFAULT_KEY_ADDRESS");
    }

    function _getEthSepoliaConfig() internal view returns (address entryPoint, address sender) {
        entryPoint = ETH_SEPOLIA_ENTRY_POINT;
        sender = vm.envAddress("DEFAULT_KEY_ADDRESS");
    }

    function _getOrCreateLocalConfig() internal pure returns (address entryPoint, address sender) {
        entryPoint = address(0);
        sender = DEFAULT_SENDER;
    }
}
