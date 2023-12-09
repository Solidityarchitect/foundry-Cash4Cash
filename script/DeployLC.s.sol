// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LendingContract} from "../src/LendingContract.sol";

contract DeployLC is Script {
    function run() external returns (LendingContract, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        (address priceFeed, address usdc, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        LendingContract lendingContract = new LendingContract(priceFeed, usdc);
        vm.stopBroadcast();
        return (lendingContract, helperConfig);
    }
}
