// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Script, console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";

contract CodeConstants {
    uint256 constant LOCAL_CHAIN_ID = 31_337;
    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant ARBITRUM_MAINNET_CHAIN_ID = 42_161;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421_614;
    uint256 constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
}

contract HelperConfig is Script, CodeConstants {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error HelperConfig__InvalidNetwork(uint256 chainId);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct NetworkConfig {
        address entryPoint;
        address usdc;
        address account;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    NetworkConfig localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) networkConfigs;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() {
        networkConfigs[ETH_MAINNET_CHAIN_ID] = _getEthMainnetConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = _getEthSepoliaConfig();
        networkConfigs[ARBITRUM_MAINNET_CHAIN_ID] = _getArbMainnetConfig();
        networkConfigs[ARBITRUM_SEPOLIA_CHAIN_ID] = _getArbSepoliaConfig();
    }

    function getConfig() external returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return _getOrCreateLocalConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidNetwork(block.chainid);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/

    function _getEthMainnetConfig() internal view returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // need to confirm later
            account: vm.envAddress("DEFAULT_KEY_ADDRESS")
        });
    }

    function _getArbMainnetConfig() internal view returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            entryPoint: 0x0000000071727De22E5E9d8BAf0edAc6f37da032,
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831, // need to confirm later
            account: vm.envAddress("DEFAULT_KEY_ADDRESS")
        });
    }

    function _getEthSepoliaConfig() internal view returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            usdc: 0xc25C21b67a9a6cB2220301918B08578E603573b5,
            account: vm.envAddress("DEFAULT_KEY_ADDRESS")
        });
    }

    function _getArbSepoliaConfig() internal view returns (NetworkConfig memory networkConfig) {
        networkConfig = NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            usdc: 0x50A7224492E22bc8923b77751E3D047c6B47CbDE,
            account: vm.envAddress("DEFAULT_KEY_ADDRESS")
        });
    }

    function _getOrCreateLocalConfig() internal returns (NetworkConfig memory) {
        // if mocks are already deployed, return struct
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }
        // otherwise, deploy mocks and save struct
        console2.log("Deploying mocks...");
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);
        EntryPoint entryPoint = new EntryPoint();
        ERC20Mock erc20Mock = new ERC20Mock();
        vm.stopBroadcast();

        localNetworkConfig =
            NetworkConfig({entryPoint: address(entryPoint), usdc: address(erc20Mock), account: ANVIL_DEFAULT_ACCOUNT});

        return localNetworkConfig;
    }
}
